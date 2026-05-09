import Foundation
import EloAds

#if canImport(GoogleMobileAds)
@preconcurrency import GoogleMobileAds

/// ``AdTracker`` shim for AdMob native ads.
///
/// AdMob records impressions and clicks automatically once a `NativeAdView`
/// is assigned a `NativeAd`. The heavy lifting lives in
/// ``AdMobNativeAdRenderer`` and ``AdMobNativeAdDelegateBridge``. This tracker
/// exists only to satisfy the ``AdTracker`` contract that ``EloAd``
/// requires, so all methods are intentional no-ops.
package struct AdMobNativeTracker: AdTracker {
    package init(nativeAd: NativeAd) {}

    package func trackRender() async {
        // No-op: AdMob has no distinct render event.
    }

    package func trackImpression() async {
        // No-op: AdMob records impressions automatically from NativeAdView.
    }

    package func trackClick() async {
        // No-op: AdMob captures clicks through registered native-ad subviews.
    }
}
#endif
