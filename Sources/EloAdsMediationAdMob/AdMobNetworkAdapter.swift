import Foundation
import EloAds

#if canImport(GoogleMobileAds)
import GoogleMobileAds

/// Google AdMob as an ``AdNetworkAdapter`` for Elo's client-side mediation.
///
/// Usage:
/// ```swift
/// Elo.configure(with: EloConfiguration(
///     elo: EloNetworkConfiguration(
///         publisherId: "YOUR_ELO_PUBLISHER_ID",  // from the Elo dashboard
///         adUnitId: "YOUR_ELO_AD_UNIT_ID"        // from the Elo dashboard
///     ),
///     adapters: [
///         // adUnitId here is the AdMob ad unit, not the Elo one.
///         AdMobNetworkAdapter(
///             adUnitId: "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYYYY",
///             expectedEcpm: 2.40 // your realized eCPM from AdMob reports
///         ),
///     ]
/// ))
/// ```
///
/// Uses AdMob's **native ad** format only — matching Elo's native-card shape
/// in v1. Banner / interstitial / rewarded can be added later once
/// `EloAdView` gains format siblings.
///
/// Rendering & billing: AdMob requires creatives to be displayed inside a
/// `NativeAdView` for impressions and clicks to count. The adapter always
/// attaches an ``AdMobNativeAdRenderer`` to the returned ``EloAd`` so
/// ``EloAdView`` embeds an AdMob-owned layout and the ad is billable.
public final class AdMobNetworkAdapter: NSObject, AdNetworkAdapter, @unchecked Sendable {
    public let networkId = "admob"

    public let requiredInfoPlistKeys: [String] = ["GADApplicationIdentifier"]

    /// AdMob's published SKAdNetwork identifiers for iOS install attribution.
    ///
    /// Loaded from the bundled `AdMobSKAdNetworkItems.plist` resource, which
    /// is sourced from Google's official iOS quick-start guide. Refresh the
    /// plist when Google updates the published list — see
    /// `Sources/EloAdsMediationAdMob/Resources/UPDATING.md`.
    public var requiredSKAdNetworkIds: [String] {
        AdMobSKAdNetworkIDs.shared
    }

    private let priceTiers: [AdMobPriceTier]
    private let rootViewControllerProvider: @MainActor @Sendable () -> UIViewController?

    /// - Parameters:
    ///   - adUnitId: AdMob native ad unit id, e.g.
    ///     `"ca-app-pub-3940256099942544/3986624511"`. The adapter loads this
    ///     unit on every bid.
    ///   - expectedEcpm: The bid value the adapter reports when AdMob fills.
    ///     `GoogleMobileAds.NativeAd` does not expose a programmatic bid
    ///     price, so this number is what Elo's first-price auction uses to
    ///     compare AdMob against other networks. Set it to your realized
    ///     eCPM for this ad unit as observed in your AdMob dashboard (a
    ///     blended last-30-day figure is a reasonable starting point). Must
    ///     be finite and `>= 0.0` (rejects `nan` and `infinity`). Zero
    ///     configures AdMob as last-resort backfill: when AdMob ties the
    ///     Elo first-party lane at `0.0`, the mediator's tie-break prefers
    ///     Elo, so AdMob only wins when no Elo bid is available and no
    ///     other adapter outbids `0.0`. Immutable for the life of the
    ///     adapter instance; to change it, construct a new adapter and
    ///     re-run ``Elo/configure(with:)``.
    ///   - rootViewController: Closure returning the view controller AdMob
    ///     should anchor its ad loading to. Use `nil` only if you know the
    ///     ad format doesn't need one.
    ///
    /// Styling, layout, and localized presentation labels are supplied by
    /// ``EloAdView`` through ``EloAdStyle``, ``EloAdLayout``, and
    /// `EloAdView`'s initializer parameters.
    public init(
        adUnitId: String,
        expectedEcpm: Double,
        rootViewController: @escaping @MainActor @Sendable () -> UIViewController? = { nil }
    ) {
        precondition(!adUnitId.isEmpty, "AdMobNetworkAdapter requires a non-empty adUnitId")
        precondition(
            expectedEcpm.isFinite && expectedEcpm >= 0.0,
            "AdMobNetworkAdapter requires a finite expectedEcpm >= 0.0; got \(expectedEcpm)"
        )
        self.priceTiers = [AdMobPriceTier(adUnitId: adUnitId, eCpm: expectedEcpm)]
        self.rootViewControllerProvider = rootViewController
        super.init()
    }

    public func start(consent: AdConsent) async throws {
        try await startGoogleMobileAds()
        // Apply the startup-time consent snapshot to AdMob's global
        // RequestConfiguration so the very first auction inherits COPPA /
        // under-age flags. Per-request consent is also applied in
        // `loadNativeAd`, but Google's SDK reads COPPA at init time on some
        // surfaces — mirror Android's behavior of seeding it here.
        Self.applyConsent(consent, requestConfiguration: MobileAds.shared.requestConfiguration)
    }

    public func bid(_ request: AdBidRequest) async throws -> AdBid? {
        try await AdMobWaterfall.firstFill(
            tiers: priceTiers,
            timeout: request.timeout,
            loadAd: { [self] adUnitId in
                guard let nativeAd = try await loadNativeAd(adUnitId: adUnitId, request: request) else {
                    return nil
                }
                return await Self.makeCreative(
                    from: nativeAd
                )
            }
        )
    }

    // MARK: - AdLoader async bridge

    private func loadNativeAd(adUnitId: String, request: AdBidRequest) async throws -> NativeAd? {
        let rootVC = await MainActor.run {
            rootViewControllerProvider()
        }
        Self.applyConsent(request.consent, requestConfiguration: MobileAds.shared.requestConfiguration)

        let gadRequest = Request()
        if let npaParameters = AdMobConsent.nonPersonalizedAdParameters(for: request.consent) {
            let extras = Extras()
            extras.additionalParameters = npaParameters
            gadRequest.register(extras)
        }

        let loader = AdMobNativeAdLoader(
            adUnitId: adUnitId,
            rootViewController: rootVC,
            request: gadRequest
        )

        // The mediator races the auction against `auctionTimeout` by cancelling
        // slow bid tasks. Without this handler the AdMob load would keep its
        // task suspended until the SDK eventually calls back, defeating the
        // timeout. `cancel()` resumes the continuation with `CancellationError`
        // and releases the loader's self-retainer so the task unblocks promptly.
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<NativeAd?, Error>) in
                loader.start(continuation: continuation)
            }
        } onCancel: {
            loader.cancel()
        }
    }

    // MARK: - Decision C — AdMob creative mapping

    /// Map a loaded `NativeAd` to Elo's `EloAd` shape and attach an
    /// ``AdRenderer`` that registers the ad with `NativeAdView` at display
    /// time so AdMob can count impressions and clicks.
    ///
    /// **This is where you decide how AdMob creatives present inside
    /// `EloAdView`.** AdMob exposes: `headline`, `body`, `images[0]`
    /// (hero), `icon`, `advertiser`, `callToAction`, `price`, `starRating`.
    /// Elo's `EloAd` has only `title`, `description`, `imageUrl`.
    ///
    /// The current mapping is the minimal viable default:
    /// - title      = headline
    /// - description = body
    /// - imageUrl   = images[0]
    ///
    /// To customize, adjust the ``AdMobNativeAssets`` passed to
    /// ``AdMobCreativeMapper/makeCreative(from:tracker:renderer:)``:
    ///
    ///   1. Append the CTA to title: `"\(headline) — \(callToAction)"`.
    ///   2. Fall back to advertiser name when body is empty.
    ///
    /// Return `nil` to reject the creative (the bid becomes a no-fill).
    @MainActor
    static func makeCreative(
        from nativeAd: NativeAd
    ) -> EloAd? {
        // Always attach a renderer. AdMob counts impressions and clicks only
        // when the creative is displayed inside a `NativeAdView`;
        // ``EloAdView`` detects the renderer and embeds the AdMob-owned
        // layout.
        let delegateBridge = AdMobNativeAdDelegateBridge()
        let renderer = AdMobNativeAdRenderer(
            nativeAd: nativeAd,
            delegateBridge: delegateBridge
        )
        let ad = AdMobCreativeMapper.makeCreative(
            from: AdMobNativeAssets(
                identifier: stableCreativeId(for: nativeAd),
                headline: nativeAd.headline,
                body: nativeAd.body,
                imageURL: nativeAd.images?.first?.imageURL?.absoluteString
            ),
            tracker: AdMobNativeTracker(nativeAd: nativeAd),
            renderer: renderer
        )
        // Wire the delegate bridge to the freshly-built ad so AdMob's
        // impression and click callbacks reach the publisher's
        // ``EloAdDelegate`` via ``Elo/trackImpression(_:)`` and
        // ``Elo/trackClick(_:)``.
        if let ad {
            delegateBridge.attach(ad: ad)
        }
        return ad
    }

    /// Derive a content-stable identifier for a loaded `NativeAd`.
    ///
    /// Prefer AdMob's `responseIdentifier` (set per ad-request on modern SDK
    /// versions) so the same creative reports the same id across load /
    /// impression / click events. Fall back to the Objective-C object pointer
    /// when the response info is unavailable — still unique for a live ad, but
    /// not stable across memory releases.
    private static func stableCreativeId(for nativeAd: NativeAd) -> String {
        if let responseId = nativeAd.responseInfo.responseIdentifier, !responseId.isEmpty {
            return "admob:\(responseId)"
        }
        return "admob:\(ObjectIdentifier(nativeAd).debugDescription)"
    }

    private func startGoogleMobileAds() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            MobileAds.shared.start { _ in
                continuation.resume()
            }
        }
    }

    private static func applyConsent(_ consent: AdConsent, requestConfiguration: RequestConfiguration) {
        // AdMob exposes COPPA / TFUA configuration globally on the request
        // configuration object. Additional TCF/GPP strings are still owned by
        // the host CMP / Google UMP, so this adapter forwards only the fields
        // the Google SDK accepts directly here.
        requestConfiguration.tagForChildDirectedTreatment = NSNumber(value: consent.coppa)
        requestConfiguration.tagForUnderAgeOfConsent = NSNumber(value: consent.tfua)
    }

}

/// Bridge AdLoader's delegate callbacks into a single-shot async return.
///
/// Construction is split from continuation registration so the surrounding
/// `withTaskCancellationHandler` can cancel the load before (or while) it is
/// in flight. The lock orders three states — `pending`, `loading`, `finished`
/// — so a cancel that races with a successful AdMob callback resolves to a
/// single resume.
private final class AdMobNativeAdLoader: NSObject, NativeAdLoaderDelegate, @unchecked Sendable {
    private let adUnitId: String
    private let rootViewController: UIViewController?
    private let request: Request

    private let lock = NSLock()
    private var continuation: CheckedContinuation<NativeAd?, Error>?
    private var loader: AdLoader?
    private var selfRetainer: AdMobNativeAdLoader?
    private var completed = false
    private var cancelledBeforeStart = false

    init(
        adUnitId: String,
        rootViewController: UIViewController?,
        request: Request
    ) {
        self.adUnitId = adUnitId
        self.rootViewController = rootViewController
        self.request = request
        super.init()
    }

    /// Register the continuation and start the AdMob load. If `cancel()` ran
    /// before this call (the task was already cancelled), resume immediately
    /// with `CancellationError` so the parent task unblocks.
    func start(continuation: CheckedContinuation<NativeAd?, Error>) {
        lock.lock()
        if cancelledBeforeStart {
            lock.unlock()
            continuation.resume(throwing: CancellationError())
            return
        }
        self.continuation = continuation
        // Keep the delegate bridge alive until AdMob calls back. Without this,
        // the local `loader` reference would drop before the SDK finishes
        // loading.
        selfRetainer = self
        let options = NativeAdViewAdOptions()
        let loader = AdLoader(
            adUnitID: adUnitId,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: [options]
        )
        loader.delegate = self
        self.loader = loader
        lock.unlock()
        loader.load(request)
    }

    /// Resolve the in-flight load with `CancellationError`. Safe to call from
    /// any thread and at any point in the loader's lifecycle: before
    /// `start(continuation:)` registers a continuation, while AdMob is
    /// loading, or after a successful resolve (last call wins are no-ops).
    func cancel() {
        lock.lock()
        if continuation == nil && !completed {
            cancelledBeforeStart = true
            lock.unlock()
            return
        }
        lock.unlock()
        finish(.failure(CancellationError()))
    }

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        finish(.success(nativeAd))
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        // AdMob treats "no fill" as an error code; translate it to a nil bid
        // rather than throwing — no-fill is a normal auction outcome.
        let ns = error as NSError
        if ns.code == RequestError.Code.noFill.rawValue {
            finish(.success(nil))
        } else {
            finish(.failure(error))
        }
    }

    private func finish(_ result: Result<NativeAd?, Error>) {
        lock.lock()
        guard !completed else {
            lock.unlock()
            return
        }
        completed = true
        let pendingContinuation = continuation
        continuation = nil
        loader = nil
        selfRetainer = nil
        lock.unlock()

        guard let pendingContinuation else { return }
        switch result {
        case .success(let ad): pendingContinuation.resume(returning: ad)
        case .failure(let err): pendingContinuation.resume(throwing: err)
        }
    }
}

#endif
