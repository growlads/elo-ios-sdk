import SwiftUI
import EloAds

// Replace these with your own publisher / ad-unit IDs from the Elo
// dashboard before shipping. The example will run with the placeholders
// in place but every request will return `.error(.notConfigured)` until
// you swap them.
private enum DemoConfig {
    static let eloPublisherID = "your-publisher-id"
    static let eloAdUnitID    = "your-ad-unit-id"
}

@main
struct EloAdsExampleApp: App {
    init() {
        Elo.initialize(
            publisherId: DemoConfig.eloPublisherID,
            adUnitId: DemoConfig.eloAdUnitID
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

            Text("Tap below to request a contextual ad based on the conversation snippet above.")
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
