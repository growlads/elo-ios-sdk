# GrowlAds Example

A SwiftUI iOS app that demonstrates a full Growl integration: SDK initialization, AdMob mediation wiring, a contextual ad request built from a chat snippet, and rendering with `GrowlAdView`.

## Run

```sh
open GrowlAdsExample.xcodeproj
```

Pick an iPhone simulator and press ▶. Tap **Load ad** to fire a request and render the result.

> **Before it returns real fills:** edit `Sources/GrowlAdsExampleApp.swift` and replace `growlPublisherID` / `growlAdUnitID` with values from your Growl dashboard. The placeholder strings are deliberately invalid so untouched runs surface as `.error(.notConfigured)` rather than silently calling out to a stranger's account. The AdMob unit ID is Google's publicly documented test native unit and can stay as-is until you wire your own AdMob account.

## What it does

- Builds a `GrowlConfiguration` with both Growl-direct demand and an `AdMobNetworkAdapter` price tier, then calls `Growl.configure(with:)` at launch.
- Sends a small two-message `[ChatMessage]` array as the ad context.
- Hands the resulting `AdResult` to `GrowlAdView`, which hides itself on no-fill / error and renders the creative on success.
- Surfaces the raw outcome below the ad slot so the demo stays informative even when there's no fill.

The auction is configured with Growl held below the AdMob price tier so the demo's auction resolves to AdMob and exercises the native renderer end-to-end. Raise `assumedECpm` (or remove the AdMob adapter) to verify Growl-direct creatives instead.

## AdMob requirements baked into `Support/Info.plist`

- `GADApplicationIdentifier` set to Google's documented test app ID. Replace with your AdMob app ID for production builds.
- `SKAdNetworkItems` includes the canonical AdMob list from [Google's iOS quick-start](https://developers.google.com/admob/ios/quick-start). iOS only honors `SKAdNetworkItems` declared in the host app's Info.plist, so this list lives here even though the adapter validates against a bundled copy at runtime.

## How `GrowlAds` is resolved

`project.yml` points the SwiftPM `GrowlAds` package at `path: ..` — i.e. this repo's own `Package.swift`, which declares the binary GrowlAds target + the source `GrowlAdsMediationAdMob` target. To demo the tagged-release flow against the live URL instead, swap the `packages:` block to:

```yaml
packages:
  GrowlAds:
    url: https://github.com/growlads/growl-ios-sdk
    from: "0.0.7"
```

## Regenerate the Xcode project

If you edit `project.yml`, regenerate `GrowlAdsExample.xcodeproj` with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
```
