# GrowlAds iOS SDK

Monetize your iOS app with contextual ads powered by [Growl](https://withgrowl.com/).

## Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 15+

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies**, then enter:

```
https://github.com/growlads/growl-ios-sdk
```

Pick **Up to Next Major Version** from `0.0.7`, and add the `GrowlAds` library to your target.

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/growlads/growl-ios-sdk", from: "0.0.7"),
]
```

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "GrowlAds", package: "growl-ios-sdk"),
    ]
),
```

`import GrowlAds` is the entire SDK surface — there's no second module to import unless you opt into AdMob mediation (see below).

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

## AdMob mediation

If you want Growl to fall back to AdMob when there's no Growl-direct fill, add the `GrowlAdsMediationAdMob` library product to your target alongside `GrowlAds`. The adapter ships as source — it pulls Google's `GoogleMobileAds` SwiftPM package transitively, which can't be vendored into the binary SDK.

**1. Add the second product to your target:**

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "GrowlAds", package: "growl-ios-sdk"),
        .product(name: "GrowlAdsMediationAdMob", package: "growl-ios-sdk"),
    ]
),
```

**2. Add `GADApplicationIdentifier` and `SKAdNetworkItems` to your app's `Info.plist`:**

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
<key>SKAdNetworkItems</key>
<array>
    <!-- Canonical AdMob list — see Example/Support/Info.plist for the
         full set, or pull from Google's iOS quick-start:
         https://developers.google.com/admob/ios/quick-start -->
</array>
```

iOS only honors `SKAdNetworkItems` declared in the host app, so this list belongs in your app's Info.plist (the adapter ships its own copy for runtime validation, but iOS doesn't read that one).

**3. Wire the adapter through `GrowlConfiguration` instead of `Growl.initialize(...)`:**

```swift
import GrowlAds
import GrowlAdsMediationAdMob

let configuration = GrowlConfiguration(
    growl: .init(
        publisherId: "your-publisher-id",
        adUnitId: "your-ad-unit-id"
    ),
    adapters: [
        AdMobNetworkAdapter(
            priceTiers: [
                AdMobPriceTier(adUnitId: "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY", eCpm: 2.0),
            ],
            rootViewController: { /* return your active UIViewController */ }
        ),
    ]
)
Growl.configure(with: configuration)
```

`priceTiers` is an ordered, highest-eCPM-first list of AdMob native ad units. Growl runs a parallel auction across `growl` (Growl-direct demand) and every adapter; the highest bid wins.

The runnable [`Example/`](Example/) demonstrates the full AdMob wiring end-to-end with public test ad units. See [Example/README.md](Example/README.md) for setup notes.

## Example

The [`Example/`](Example/) folder contains a runnable iOS app you can open in Xcode to see the full integration end-to-end.

```sh
cd Example
open GrowlAdsExample.xcodeproj
```

Press ▶ in Xcode (iPhone simulator) and tap **Load ad** to fire a contextual request. Replace the placeholder publisher/ad-unit IDs in `Sources/GrowlAdsExampleApp.swift` with values from your Growl dashboard before expecting real fills.

## Crash reporting

dSYM files for symbolicating crashes are attached to each [GitHub release](https://github.com/growlads/growl-ios-sdk/releases). Drop the matching version's archive into Crashlytics, Sentry, or Xcode Organizer.

## License

See [LICENSE](LICENSE).
