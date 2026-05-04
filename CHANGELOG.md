# Changelog

All notable changes to the Elo iOS SDK distribution are documented here. The XCFramework binary is published to GitHub Releases; this file tracks what each tagged release contains.

## Unreleased

## 0.0.1 — 2026-04-15

Initial public release. SDK distributed as an XCFramework via Swift Package Manager.

- `Growl` entry point: `configure`, `loadAd`, `preloadAd`, `setDelegate`, `mediationDebugSnapshot`, `enable`/`disable`, `shutdown`.
- SwiftUI ad views: `GrowlAdView`, `GrowlBadgeAdView`, `GrowlChatAdView` with automatic render/impression/click tracking (impression fires after ≥50% visible for 1s).
- Manual tracking hooks: `Growl.trackRender`, `Growl.trackImpression`, `Growl.trackClick`.
- Optional AdMob mediation via the `GrowlAdsMediationAdMob` product (source target).
- Minimum deployment target: iOS 16.

> The `Growl*` symbol names reflect the historical brand; the consumer-facing product is **Elo** ([elo.ad](https://elo.ad)).
