# Changelog

## Unreleased

## 0.1.1 — 2026-05-24

- refactor(ios): trim EloConfiguration to Android parity (#12)
- docs(mediation): fix AdMob adapter doc nits flagged on dist PR #14 (#10)
- docs(ios): pin README SwiftPM snippets at exact 0.1.0 (#9)

## Unreleased

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
