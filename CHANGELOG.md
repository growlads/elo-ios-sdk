# Changelog

All notable changes to the Elo iOS SDK distribution are documented here. The XCFramework binary is published to GitHub Releases; this file tracks what each tagged release contains.

## Unreleased

## 0.0.1 — 2026-04-15

Initial public release. SDK distributed as an XCFramework via Swift Package Manager.

- `Elo` entry point: `configure`, `loadAd`, `preloadAd`, `setDelegate`, `mediationDebugSnapshot`, `enable`/`disable`, `shutdown`.
- SwiftUI ad views: `EloAdView`, `EloBadgeAdView`, `EloChatAdView` with automatic render/impression/click tracking (impression fires after ≥50% visible for 1s).
- Manual tracking hooks: `Elo.trackRender`, `Elo.trackImpression`, `Elo.trackClick`.
- Optional AdMob mediation via the `EloAdsMediationAdMob` product (source target).
- Minimum deployment target: iOS 16.
