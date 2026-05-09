import SwiftUI
import UIKit
import EloAds
import EloAdsMediationAdMob

// Replace these with your own publisher / ad-unit IDs from the Elo
// dashboard before shipping. The example will run with the placeholders
// in place but every Elo-direct request will return `.error(.notConfigured)`
// until you swap them. The AdMob ad-unit below is Google's documented
// public test unit and is safe to use unchanged in the demo.
private enum DemoConfig {
    static let eloPublisherID = "your-publisher-id"
    static let eloAdUnitID    = "your-ad-unit-id"
    static let admobTestNativeAdUnitID = "ca-app-pub-3940256099942544/3986624511"
}

@main
struct EloAdsExampleApp: App {
    init() {
        // `Elo.configure(with:)` is the mediation-aware entry point.
        // For an Elo-only integration you can stick with the shorter
        // `Elo.initialize(publisherId:adUnitId:)` form; using `configure`
        // here so the demo also exercises the AdMob mediation adapter.
        Elo.configure(
            with: EloConfiguration(
                elo: EloNetworkConfiguration(
                    publisherId: DemoConfig.eloPublisherID,
                    adUnitId: DemoConfig.eloAdUnitID
                ),
                adapters: [
                    AdMobNetworkAdapter(
                        adUnitId: DemoConfig.admobTestNativeAdUnitID,
                        rootViewController: { RootViewControllerFinder.current() }
                    ),
                ]
            )
        )
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
            Text("Elo Ads Demo")
                .font(.largeTitle.bold())

            Text("Tap below to request a contextual ad. The auction runs Elo-direct and AdMob in parallel; the higher-eCPM creative renders.")
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

            // EloAdView renders the loaded ad and hides itself on
            // `.noFill` / `.error`, so handing it the result directly is
            // the path of least resistance.
            EloAdView(result: adResult)
                .padding(.horizontal)

            if let adResult { outcomeRow(for: adResult) }

            Spacer()
        }
        .padding()
    }

    private func loadAd() {
        isLoading = true
        Task {
            adResult = await Elo.loadAd(messages: messages)
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

// AdMobNetworkAdapter needs a UIViewController to anchor click-handling
// when an AdMob native creative wins the auction. SwiftUI doesn't expose
// a stable presenter, so this walks the connected window scenes for the
// current key window's root controller. Same helper the source-repo
// example uses.
private enum RootViewControllerFinder {
    @MainActor
    static func current() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}
