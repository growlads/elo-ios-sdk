# Elo Example

A SwiftUI iOS app that demonstrates a minimal Elo integration with AdMob mediation: SDK configuration, a contextual ad request built from a chat snippet, and rendering with `EloAdView`.

## Run

```sh
open EloAdsExample.xcodeproj
```

Pick an iPhone simulator and press ▶. Tap **Load ad** to fire a request and render the result.

> **Before it returns real fills:** edit `Sources/EloAdsExampleApp.swift` and replace `eloPublisherID` / `eloAdUnitID` with values from your Elo dashboard. The placeholder strings are deliberately invalid so untouched runs surface as a no-fill / error outcome rather than silently calling out to a stranger's account. The AdMob ad-unit is Google's public native test unit and works unchanged.

## What it does

- Calls `Elo.configure(with:)` at launch, registering the AdMob mediation adapter alongside Elo-direct demand. Adapter setup (app ID, `expectedEcpm`, consent) is documented in the [Mediation section of the root README](../README.md#mediation-optional).
- Sends a small two-message `[ChatMessage]` array as the ad context via `Elo.loadAd(messages:)`.
- Hands the resulting `AdResult` to `EloAdView`, which hides itself on no-fill / error and renders the creative on success.
- Surfaces the raw outcome below the ad slot so the demo stays informative even when there's no fill.

## How `EloAds` is resolved

`project.yml` pins the SwiftPM `EloAds` package to this repo's release URL with `exactVersion`. The release workflow keeps the pin in lockstep with each published version, so the demo always builds against the matching release. To build against your local checkout of this repo instead, swap the `packages:` block to:

```yaml
packages:
  EloAds:
    path: ..
```

## Regenerate the Xcode project

The checked-in `EloAdsExample.xcodeproj` is generated from `project.yml` by the release workflow. If you edit `project.yml`, regenerate with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
```
