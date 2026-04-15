# GrowlAds iOS SDK

Monetize your iOS app with contextual ads powered by [Growl](https://withgrowl.com/).

## Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 5.9+
- Xcode 15+

## Installation

### Swift Package Manager

Add GrowlAds to your project in Xcode:

1. **File → Add Package Dependencies**
2. Enter the repository URL:
   ```
   https://github.com/growlads/growl-ios-sdk
   ```
3. Select **Up to Next Major Version** from `0.0.4`

Or add it directly to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/growlads/growl-ios-sdk", from: "0.0.4"),
]
```

Then add `GrowlAds` to your target's dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "GrowlAds", package: "growl-ios-sdk"),
    ]
),
```

## Quick Start

```swift
import GrowlAds

// Initialize the SDK with your credentials
Growl.initialize(publisherId: "your-publisher-id", adUnitId: "your-ad-unit-id")

// Load an ad with conversation context
let messages: [ChatMessage] = [
    ChatMessage(role: .user, content: "What's the best running shoe?"),
    ChatMessage(role: .assistant, content: "Here are some top picks..."),
]

let result = await Growl.loadAd(messages: messages)

switch result {
case .loaded(let ad):
    // Display the ad using GrowlAdView
    GrowlAdView(ad: ad)
case .noFill:
    // No ad available for this context
    break
case .error(let message):
    print("Ad error: \(message)")
}
```

## SwiftUI Integration

```swift
struct ChatView: View {
    @State private var adResult: AdResult?

    var body: some View {
        VStack {
            // Your chat content...

            if let result = adResult {
                GrowlAdView(result: result)
                    .growlAdStyle(GrowlAdStyle(
                        cardBackground: .white,
                        cornerRadius: 12
                    ))
            }
        }
        .task {
            adResult = await Growl.loadAd(messages: messages)
        }
    }
}
```

## Crash Reporting

Each [GitHub release](https://github.com/growlads/growl-ios-sdk/releases) includes dSYM files for crash symbolication with Crashlytics, Sentry, or other tools.

## License

This SDK is available under the MIT License. See [LICENSE](LICENSE) for details.
