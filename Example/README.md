# GrowlAds Example

A minimal SwiftUI iOS app that demonstrates the full Growl integration: SDK initialization, a contextual ad request built from a chat snippet, and rendering with `GrowlAdView`.

## Run

```sh
open GrowlAdsExample.xcodeproj
```

Pick an iPhone simulator and press ▶. Tap **Load ad** to fire a request and render the result.

## What it does

- Calls `Growl.initialize(...)` on app launch with public test credentials (see `Sources/GrowlAdsExampleApp.swift` — replace with your own publisher / ad-unit IDs once you have them).
- Sends a small two-message `[ChatMessage]` array as the ad context.
- Hands the resulting `AdResult` to `GrowlAdView`, which hides itself on no-fill / error and renders the creative on success.
- Surfaces the raw outcome below the ad slot so the demo stays informative even when there's no fill.

## How `GrowlAds` is resolved

`project.yml` points the SwiftPM `GrowlAds` package at `path: ..` — i.e. this repo's own `Package.swift`, which declares the binaryTargets that pull the `.xcframework.zip`s from the matching GitHub release. To demo the tagged-release flow against the live URL instead, swap the `packages:` block to:

```yaml
packages:
  GrowlAds:
    url: https://github.com/growlads/growl-ios-sdk
    from: "0.0.5"
```

## Regenerate the Xcode project

If you edit `project.yml`, regenerate `GrowlAdsExample.xcodeproj` with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
```
