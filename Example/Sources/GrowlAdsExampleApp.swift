import SwiftUI
import UIKit
import GrowlAds
import GrowlAdsMediationAdMob

// Replace these with your own publisher / ad-unit IDs from the Growl
// dashboard before shipping. The example will run with the placeholders
// in place but every request will return `.error(.notConfigured)` until
// you swap them.
//
// `admobNativeAdUnitID` is Google's documented public test native unit —
// safe to commit; replace it with your own AdMob native unit ID for
// production builds. See:
//   https://developers.google.com/admob/ios/test-ads
private enum DemoConfig {
    static let growlPublisherID = "your-publisher-id"
    static let growlAdUnitID    = "your-ad-unit-id"
    static let admobNativeAdUnitID = "ca-app-pub-3940256099942544/3986624511"
}

@main
struct GrowlAdsExampleApp: App {
    init() {
        // GrowlConfiguration is the long-form initializer when you want
        // to wire mediation adapters or override defaults. Use
        // `Growl.initialize(publisherId:adUnitId:)` instead if you only
        // need Growl-direct demand.
        let configuration = GrowlConfiguration(
            growl: .init(
                publisherId: DemoConfig.growlPublisherID,
                adUnitId: DemoConfig.growlAdUnitID,
                // Held below the AdMob price tier (2.0) so the auction
                // resolves to AdMob and the AdMob native renderer fires.
                // Raise (or remove) this to verify Growl-direct creatives.
                assumedECpm: 0.5
            ),
            logLevel: .debug,
            adapters: [
                AdMobNetworkAdapter(
                    priceTiers: [
                        AdMobPriceTier(adUnitId: DemoConfig.admobNativeAdUnitID, eCpm: 2.0),
                    ],
                    rootViewController: { RootViewControllerFinder.current() }
                ),
            ]
        )
        Growl.configure(with: configuration)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var adResult: AdResult?
    @State private var isLoading = false

    private let messages: [ChatMessage] = [
        ChatMessage(role: .user, content: "What's the best running shoe for marathon training?"),
        ChatMessage(role: .assistant, content: "For marathon training, you'll want shoes with good cushioning and durability. Brands like Hoka, Nike, and Brooks are popular picks."),
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("Growl Ads Demo")
                .font(.largeTitle.bold())

            Text("Tap below to request a contextual ad based on the conversation snippet above. The demo wires AdMob mediation; see GrowlAdsExampleApp for the configuration.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: loadAd) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Load ad")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            // GrowlAdView renders the loaded ad and hides itself on
            // `.noFill` / `.error`, so handing it the result directly is
            // the path of least resistance.
            GrowlAdView(result: adResult)
                .padding(.horizontal)

            if let adResult { outcomeRow(for: adResult) }

            Spacer()
        }
        .padding()
    }

    private func loadAd() {
        isLoading = true
        Task {
            adResult = await Growl.loadAd(messages: messages)
            isLoading = false
        }
    }

    @ViewBuilder
    private func outcomeRow(for result: AdResult) -> some View {
        let (label, color): (String, Color) = switch result {
        case .loaded:           ("Loaded",  .green)
        case .noFill(let r):    ("No fill: \(r)", .orange)
        case .error(let m):     ("Error: \(m)",   .red)
        }
        Text(label)
            .font(.footnote.monospaced())
            .foregroundStyle(color)
    }
}

/// Walks the active scene's window hierarchy to find a host view
/// controller for AdMob to anchor click-out modals against. Required
/// because `AdMobNetworkAdapter` doesn't take a UIWindow itself.
@MainActor
enum RootViewControllerFinder {
    static func current() -> UIViewController? {
        guard
            let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first,
            let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
        else { return nil }
        return window.rootViewController
    }
}
