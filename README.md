# Elo iOS SDK

Monetize your iOS app with contextual ads powered by [Elo](https://elo.ad/).

## Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 15+

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies**, then enter:

```
https://github.com/growlads/elo-ios-sdk
```

Pick **Up to Next Major Version** from `0.0.1`, and add the `GrowlAds` library to your target.

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/growlads/elo-ios-sdk", from: "0.0.1"),
]
```

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "GrowlAds", package: "elo-ios-sdk"),
    ]
),
```

`import GrowlAds` is the entire SDK surface.

## Quick start

```swift
import GrowlAds

// 1. Initialize once at app launch.
Growl.initialize(
    publisherId: "your-publisher-id",
    adUnitId: "your-ad-unit-id"
)

// 2. Build a request from the surrounding conversation.
let messages: [ChatMessage] = [
    ChatMessage(role: .user, content: "What's the best running shoe?"),
    ChatMessage(role: .assistant, content: "Here are some top picks..."),
]

// 3. Ask for an ad. `loadAd` is non-throwing and returns an exhaustive enum.
let result = await Growl.loadAd(messages: messages)

switch result {
case .loaded(let ad):
    print("Ad loaded: \(ad)")
case .noFill(let reason):
    // Not an error — just no match for this context.
    print("No fill: \(reason)")
case .error(let message):
    print("Ad error: \(message)")
}
```

## SwiftUI

`GrowlAdView` accepts an `AdResult` directly and hides itself on `.noFill` or `.error`, so you can hand it the result without branching:

```swift
import SwiftUI
import GrowlAds

struct ChatView: View {
    @State private var adResult: AdResult?

    let messages: [ChatMessage] = [
        ChatMessage(role: .user, content: "What's the best running shoe?"),
        ChatMessage(role: .assistant, content: "Here are some top picks..."),
    ]

    var body: some View {
        VStack {
            // ...your chat content...

            GrowlAdView(result: adResult)
        }
        .task {
            adResult = await Growl.loadAd(messages: messages)
        }
    }
}
```

## Mediation (optional)

Elo runs a parallel first-price auction across its own demand and any mediation adapters you register. Adapters are opt-in: each one is a separate library product on this same package, so you only link the networks you actually want bidding.

### Available adapters

| Network | Product | Status |
|---------|---------|--------|
| AdMob | `GrowlAdsMediationAdMob` | First-party |

> Heads up: the AdMob adapter used to live in a separate `elo-ios-mediation` package. As of this release it ships from the same SwiftPM package as the core SDK — drop the second `.package(url:)` line and add `GrowlAdsMediationAdMob` to your target dependencies.

### Wiring it up

Add the `GrowlAdsMediationAdMob` product to your target and switch from `Growl.initialize` to `Growl.configure(with:)` so you can pass an `adapters` list:

```swift
dependencies: [
    .package(url: "https://github.com/growlads/elo-ios-sdk", from: "0.0.1"),
],
targets: [
    .target(
        name: "YourApp",
        dependencies: [
            .product(name: "GrowlAds", package: "elo-ios-sdk"),
            .product(name: "GrowlAdsMediationAdMob", package: "elo-ios-sdk"),
        ]
    ),
]
```

```swift
import GrowlAds
import GrowlAdsMediationAdMob

Growl.configure(
    with: GrowlConfiguration(
        growl: GrowlNetworkConfiguration(
            publisherId: "YOUR_PUBLISHER_ID",
            adUnitId: "YOUR_AD_UNIT_ID"
        ),
        adapters: [/* AdMobNetworkAdapter(priceTiers: [...], ...) */]
    )
)
```

Render, click, and impression telemetry are unchanged — adapter creatives surface through the same `GrowlAdView` / `GrowlBadgeAdView` / `GrowlChatAdView` components.

Per-adapter setup (manifest keys, price tiers, consent forwarding) lives in [`Sources/GrowlAdsMediationAdMob/README.md`](Sources/GrowlAdsMediationAdMob/README.md). The v1 contract for writing your own adapter is documented in [`ADAPTER_AUTHOR_GUIDE.md`](https://github.com/growlads/elo-ios-sdk-source/blob/main/ADAPTER_AUTHOR_GUIDE.md) in the source repo.

## Example

The [`Example/`](Example/) folder contains a runnable iOS app you can open in Xcode to see the full integration end-to-end.

```sh
cd Example
open GrowlAdsExample.xcodeproj
```

Press ▶ in Xcode (iPhone simulator) and tap **Load ad** to fire a contextual request. Replace the placeholder publisher/ad-unit IDs in `Sources/GrowlAdsExampleApp.swift` with values from your Elo dashboard before expecting real fills.

## Crash reporting

dSYM files for symbolicating crashes are attached to each [GitHub release](https://github.com/growlads/elo-ios-sdk/releases). Drop the matching version's archive into Crashlytics, Sentry, or Xcode Organizer.

## License

See [LICENSE](LICENSE).
