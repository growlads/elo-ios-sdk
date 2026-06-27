# Changelog

## Unreleased

## 0.1.4 — 2026-06-27

- chore(ios): bump SDK version to 0.1.4 (#20)
- fix(ios): send OpenRTB device signals (#19)

## 0.1.3 — 2026-05-31

- Ship `EloAdsMediationAdMob` as a binary XCFramework alongside `EloAds`.
- Add a linker dependency target so AdMob consumers receive the Google Mobile Ads dependencies through SwiftPM.
- Keep release tags pointed at the generated SwiftPM package commit.

## 0.1.2 — 2026-05-24

Move native ad presentation control to `EloAdView` so Elo-direct and
AdMob-rendered cards share the same SwiftUI styling path. This release also
includes the configuration and AdMob documentation updates that were prepared
for the superseded `0.1.1` package update.

- Added view-level `EloAdLayout`, `.eloAdLayout(...)`, and renderer configuration propagation.
- Removed AdMob adapter initializer presentation knobs; `AdMobNetworkAdapter` now only handles network configuration.
- Deprecated `AdMobNativeStyle` and `AdMobNativeLayout` in favor of `EloAdStyle` and `EloAdLayout`.
- Rebuilt renderer-backed native views when layout/style/label configuration changes on an already-mounted `EloAdView`.
- Simplified `EloConfiguration` around publisher/ad-unit identity, privacy
  flags, log level, and optional mediation adapters.
- Replaced legacy ad view variants with the single SwiftUI `EloAdView` surface.
- Added AdMob `expectedEcpm` bidding, compact native layout updates, and
  no-CTA rendering.
- Standardized impression tracking at 50% visible for 1 second.
- Updated README snippets for the `0.1.2` package and current AdMob API.

## 0.1.0 — 2026-05-09

Rebrand from Growl to Elo across the SDK surface so iOS naming matches the Android SDK (`ad.elo.androidsdk`). No behavior change.

- Swift module `GrowlAds` → `EloAds`; mediation adapter target `GrowlAdsMediationAdMob` → `EloAdsMediationAdMob`.
- Public namespace `Growl` → `Elo`; all `GrowlFoo` types → `EloFoo` (`EloAd`, `EloAdView`, `EloAdDelegate`, `EloConfiguration`, `EloChatSession`, `EloState`, `EloError`, `EloAdStyle`, etc.).
- Lowercase: `Configuration.growl` → `.elo`; delegate callbacks `growlAdDid*` → `eloAdDid*`; `.growlAdStyle` modifier → `.eloAdStyle`; default network ID `"growl"` → `"elo"`.
- XCFramework artifact `GrowlAds.xcframework.zip` → `EloAds.xcframework.zip`.
- **Breaking change:** existing 0.0.x consumers must migrate symbol names; there is no shim. Per the project's pre-1.0 contract, breaking changes are expected on minor bumps.

## 0.0.1 — 2026-04-15

Initial public release. SDK distributed as an XCFramework via Swift Package Manager.

- `Elo` entry point: `configure`, `loadAd`, `preloadAd`, `setDelegate`, `mediationDebugSnapshot`, `enable`/`disable`, `shutdown`.
- SwiftUI ad views: `EloAdView`, `EloBadgeAdView`, `EloChatAdView` with automatic render/impression/click tracking (impression fires after ≥50% visible for 1s).
- Manual tracking hooks: `Elo.trackRender`, `Elo.trackImpression`, `Elo.trackClick`.
- Optional AdMob mediation via the `EloAdsMediationAdMob` product (source target).
- Minimum deployment target: iOS 16.
