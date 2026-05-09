# Elo Example

A SwiftUI iOS app that demonstrates a minimal Elo integration: SDK initialization, a contextual ad request built from a chat snippet, and rendering with `EloAdView`.

## Run

```sh
open EloAdsExample.xcodeproj
```

Pick an iPhone simulator and press ▶. Tap **Load ad** to fire a request and render the result.

> **Before it returns real fills:** edit `Sources/EloAdsExampleApp.swift` and replace `eloPublisherID` / `eloAdUnitID` with values from your Elo dashboard. The placeholder strings are deliberately invalid so untouched runs surface as `.error(.notConfigured)` rather than silently calling out to a stranger's account.

## What it does

- Calls `Elo.initialize(publisherId:adUnitId:)` at launch.
- Sends a small two-message `[ChatMessage]` array as the ad context.
- Hands the resulting `AdResult` to `EloAdView`, which hides itself on no-fill / error and renders the creative on success.
- Surfaces the raw outcome below the ad slot so the demo stays informative even when there's no fill.

## Adding mediation

This example demonstrates Elo-direct demand only. To wire mediation adapters (AdMob, AppLovin, etc.), add the `EloAdsMediationAdMob` product (ships from this same SwiftPM package as of v0.0.8) to your target and use the long-form `Elo.configure(with: EloConfiguration(...))` initializer to register adapters. Per-adapter setup is documented in [`Sources/EloAdsMediationAdMob/README.md`](../Sources/EloAdsMediationAdMob/README.md).

## How `EloAds` is resolved

`project.yml` points the SwiftPM `EloAds` package at `path: ..` — i.e. this repo's own `Package.swift`, which declares the binary `EloAds` xcframework target. To demo the tagged-release flow against the live URL instead, swap the `packages:` block to:

```yaml
packages:
  EloAds:
    url: https://github.com/growlads/elo-ios-sdk
    from: "0.0.1"
```

## Regenerate the Xcode project

If you edit `project.yml`, regenerate `EloAdsExample.xcodeproj` with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
```
