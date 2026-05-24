import Foundation
import EloAds

#if canImport(GoogleMobileAds)
@preconcurrency import GoogleMobileAds

/// ``AdTracker`` shim for AdMob native ads.
///
/// AdMob records impressions and clicks automatically once a `NativeAdView`
/// is assigned a `NativeAd`. The heavy lifting lives in
/// ``AdMobNativeAdRenderer`` and ``AdMobNativeAdDelegateBridge``. This
/// tracker holds a strong reference to the `NativeAd` so it can release it
/// promptly when the mediator drops a losing bid or evicts a preload entry —
/// mirrors the Android `AdMobNativeTracker.releaseResources` contract.
package final class AdMobNativeTracker: AdTracker, @unchecked Sendable {
    private let lock = NSLock()
    private var nativeAd: NativeAd?

    package init(nativeAd: NativeAd) {
        self.nativeAd = nativeAd
    }

    package func trackRender() async {
        // No-op: AdMob has no distinct render event.
    }

    package func trackImpression() async {
        // No-op: AdMob records impressions automatically from NativeAdView.
    }

    package func trackClick() async {
        // No-op: AdMob captures clicks through registered native-ad subviews.
    }

    package func releaseResources() {
        lock.lock()
        let toRelease = nativeAd
        nativeAd = nil
        lock.unlock()
        // Drop on the main actor — `GADNativeAd`'s deinit walks UIKit state
        // and expects the main thread.
        if let toRelease {
            Task { @MainActor in
                _ = toRelease
            }
        }
    }
}
#endif
