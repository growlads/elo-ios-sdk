import SwiftUI
import EloAds

// Replace these with your own publisher / ad-unit IDs from the Elo
// dashboard before shipping. The example will run with the placeholders
// in place but requests won't return real fills until you swap them.
// Untouched runs surface as a no-fill / error outcome rather than
// silently calling out to a stranger's account.
private enum DemoConfig {
    static let eloPublisherID = "your-publisher-id"
    static let eloAdUnitID    = "your-ad-unit-id"
}

@main
struct EloAdsExampleApp: App {
    init() {
        // `Elo.configure(with:)` is the SDK's single entry point. Elo is
        // the only demand source here; see `loadAd()` for where a backup
        // network takes over on no-fill.
        Elo.configure(
            with: EloConfiguration(
                elo: EloNetworkConfiguration(
                    publisherId: DemoConfig.eloPublisherID,
                    adUnitId: DemoConfig.eloAdUnitID
                )
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

    // Each turn gets its `id` and `createdAt` once, when it is created, and
    // keeps them on every request: Elo uses them to date the turn and to
    // match it to Search API calls that send the id as `X-Elo-Message-Id`.
    private static let messages: [ChatMessage] = {
        let now = Date()
        return [
            ChatMessage(
                role: .user,
                content: "What's the best running shoe for marathon training?",
                id: UUID().uuidString,
                createdAt: now
            ),
            ChatMessage(
                role: .assistant,
                content: "For marathon training, you'll want shoes with good cushioning and durability. Brands like Hoka, Nike, and Brooks are popular picks.",
                id: UUID().uuidString,
                createdAt: now
            ),
        ]
    }()

    var body: some View {
        VStack(spacing: 24) {
            Text("Elo Ads Demo")
                .font(.largeTitle.bold())

            Text("Tap below to request a contextual ad. On no-fill, this is where your app would hand the slot to a backup network.")
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

            // EloAdView renders the loaded ad, handles impression and click
            // lifecycle events, and hides itself on `.noFill` / `.error`.
            // Elo-direct clicks still open the destination while client-side
            // click POST delivery is temporarily disabled.
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
            // No `maxHeight`: the slot below has unbounded height, so the
            // server may choose the card. Pass the space your slot has.
            adResult = await Elo.loadAd(messages: Self.messages)
            isLoading = false
            // Publisher-side fallback goes here: on `.noFill` / `.error`,
            // hand the same slot to your backup ad network. This demo only
            // reports the outcome below the slot.
        }
    }

    @ViewBuilder
    private func outcomeRow(for result: AdResult) -> some View {
        // `AdResult` ships in a binary framework, so it can grow cases in
        // future SDK releases — hence `@unknown default`.
        let (label, color): (String, Color) = switch result {
        case .loaded:           ("Loaded",  .green)
        case .noFill(let r):    ("No fill: \(r)", .orange)
        case .error(let m):     ("Error: \(m)",   .red)
        @unknown default:       ("Unknown result", .secondary)
        }
        Text(label)
            .font(.footnote.monospaced())
            .foregroundStyle(color)
    }
}
