# GrowlAds Example

A SwiftUI iOS app that demonstrates a minimal Growl integration: SDK initialization, a contextual ad request built from a chat snippet, and rendering with `GrowlAdView`.

## Run

```sh
open GrowlAdsExample.xcodeproj
```

Pick an iPhone simulator and press ▶. Tap **Load ad** to fire a request and render the result.

> **Before it returns real fills:** edit `Sources/GrowlAdsExampleApp.swift` and replace `growlPublisherID` / `growlAdUnitID` with values from your Growl dashboard. The placeholder strings are deliberately invalid so untouched runs surface as `.error(.notConfigured)` rather than silently calling out to a stranger's account.

## What it does

- Calls `Growl.initialize(publisherId:adUnitId:)` at launch.
- Sends a small two-message `[ChatMessage]` array as the ad context.
- Hands the resulting `AdResult` to `GrowlAdView`, which hides itself on no-fill / error and renders the creative on success.
- Surfaces the raw outcome below the ad slot so the demo stays informative even when there's no fill.

## Adding mediation

This example demonstrates Growl-direct demand only. To wire mediation adapters (AdMob, AppLovin, etc.), add the [`elo-ios-mediation`](https://github.com/growlads/elo-ios-mediation) package as a dependency and use the long-form `Growl.configure(with: GrowlConfiguration(...))` initializer to register adapters.

## How `GrowlAds` is resolved

`project.yml` points the SwiftPM `GrowlAds` package at `path: ..` — i.e. this repo's own `Package.swift`, which declares the binary `GrowlAds` xcframework target. To demo the tagged-release flow against the live URL instead, swap the `packages:` block to:

```yaml
packages:
  GrowlAds:
    url: https://github.com/growlads/growl-ios-sdk
    from: "0.0.1"
```

## Regenerate the Xcode project

If you edit `project.yml`, regenerate `GrowlAdsExample.xcodeproj` with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
```
