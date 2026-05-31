import Foundation
import EloAds

#if canImport(GoogleMobileAds)
@preconcurrency import GoogleMobileAds

/// Forwards `NativeAdDelegate` callbacks into Elo's public tracking path
/// so `EloAdDelegate` impression and click notifications fire for AdMob
/// fills the same way they fire for Elo-sourced creatives.
///
/// AdMob counts impressions and clicks itself once the creative is registered
/// against a `NativeAdView`. This bridge mirrors those signals into
/// ``Elo/trackImpression(_:)`` / ``Elo/trackClick(_:)`` so the publisher's
/// delegate sees them. ``AdTrackingRegistry`` deduplicates impressions by ad
/// id, so a duplicate fire from the SwiftUI viewability tracker for the same
/// ad is a no-op.
final class AdMobNativeAdDelegateBridge: NSObject, NativeAdDelegate, @unchecked Sendable {
    private let onImpression: @Sendable (EloAd) -> Void
    private let onClick: @Sendable (EloAd) -> Void

    private let lock = NSLock()
    private var attachedAd: EloAd?

    init(
        onImpression: @escaping @Sendable (EloAd) -> Void = Elo.trackImpression,
        onClick: @escaping @Sendable (EloAd) -> Void = Elo.trackClick
    ) {
        self.onImpression = onImpression
        self.onClick = onClick
        super.init()
    }

    /// Wire the bridge to the ``EloAd`` it represents. Called from
    /// ``AdMobNetworkAdapter/makeCreative(from:)`` after the creative is built;
    /// the bridge stays inert until then so AdMob callbacks that arrive before
    /// the ad is fully attached are dropped rather than passed an empty value.
    func attach(ad: EloAd) {
        lock.lock()
        defer { lock.unlock() }
        attachedAd = ad.withoutRenderer()
    }

    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        guard let ad = currentAd() else { return }
        onImpression(ad)
    }

    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        guard let ad = currentAd() else { return }
        onClick(ad)
    }

    private func currentAd() -> EloAd? {
        lock.lock()
        defer { lock.unlock() }
        return attachedAd
    }
}

private extension EloAd {
    func withoutRenderer() -> EloAd {
        EloAd(
            id: id,
            title: title,
            description: description,
            imageUrl: imageUrl,
            clickUrl: clickUrl,
            tracker: tracker
        )
    }
}
#endif
