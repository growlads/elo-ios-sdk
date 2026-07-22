import SwiftUI
import EloAds
import EloAdsMediationAdMob

// Replace these with your own publisher / ad-unit IDs from the Elo
// dashboard before shipping. The example will run with the placeholders
// in place but Elo-direct requests won't return real fills until you
// swap them — untouched runs surface as a no-fill / error outcome rather
// than silently calling out to a stranger's account. The AdMob ad-unit
// below is Google's documented public test unit and is safe to use
// unchanged in the demo.
private enum DemoConfig {
    static let eloPublisherID = "your-publisher-id"
    static let eloAdUnitID    = "your-ad-unit-id"
    static let admobTestNativeAdUnitID = "ca-app-pub-3940256099942544/3986624511"
}

@main
struct EloAdsExampleApp: App {
    init() {
        // `Elo.configure(with:)` is the SDK's single entry point; the
        // `adapters` list below is what opts this demo into AdMob
        // mediation. Leave it empty for an Elo-only integration.
        Elo.configure(
            with: EloConfiguration(
                elo: EloNetworkConfiguration(
                    publisherId: DemoConfig.eloPublisherID,
                    adUnitId: DemoConfig.eloAdUnitID
                ),
                adapters: [
                    AdMobNetworkAdapter(
                        adUnitId: DemoConfig.admobTestNativeAdUnitID,
                        // GoogleMobileAds native ads don't expose a bid
                        // price, so Elo's first-price auction compares
                        // AdMob using this fixed eCPM. Set it to your
                        // realized AdMob value in production.
                        expectedEcpm: 1.0
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
    // Two independent conversations, each rendering a contextual ad in one of
    // the two EloAdLayout formats so the demo shows both side by side. Each
    // `EloAdView(messages:layout:)` runs its own auction (Elo-direct + AdMob in
    // parallel) and renders the higher-eCPM creative in the requested layout.
    private let shoeConversation: [ChatMessage] = [
        ChatMessage(role: .user, content: "What's the best running shoe for marathon training?"),
        ChatMessage(role: .assistant, content: "For marathon training, you'll want shoes with good cushioning and durability. Brands like Hoka, Nike, and Brooks are popular picks."),
    ]

    private let coffeeConversation: [ChatMessage] = [
        ChatMessage(role: .user, content: "How do I make espresso at home without a fancy machine?"),
        ChatMessage(role: .assistant, content: "A stovetop Moka pot gets you close for very little money. Use fine ground coffee, medium heat, and pull it off the stove as soon as it starts sputtering."),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Two chat threads, one ad each — the top slot uses the compact horizontal card, the bottom slot uses the inline banner.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Format 1: compact horizontal card.
                    AdFormatSection(
                        format: "compactHorizontal",
                        messages: shoeConversation,
                        layout: .compactHorizontal
                    )

                    Divider()

                    // Format 2: inline banner strip.
                    AdFormatSection(
                        format: "inlineBanner",
                        messages: coffeeConversation,
                        layout: .inlineBanner
                    )
                }
                .padding()
            }
            .navigationTitle("Elo Ads Demo")
        }
    }
}

/// One chat thread followed by an ad in a specific layout, plus a small
/// outcome label so the demo doubles as an integration smoke test.
private struct AdFormatSection: View {
    let format: String
    let messages: [ChatMessage]
    let layout: EloAdLayout

    @State private var adResult: AdResult?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(format)
                .font(.footnote.monospaced().bold())
                .foregroundStyle(.secondary)

            ForEach(messages, id: \.self) { message in
                ChatBubble(message: message)
            }

            // EloAdView loads the ad from the conversation, renders it in the
            // requested layout, handles impression and click lifecycle events,
            // and hides itself on `.noFill` / `.error`. Elo-direct clicks still
            // open the destination while client-side click POST delivery is
            // temporarily disabled.
            EloAdView(
                messages: messages,
                onResult: { adResult = $0 },
                layout: layout
            )

            if let adResult { outcomeRow(for: adResult) }
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

/// A minimal chat bubble so the ad has believable surrounding context.
private struct ChatBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            Text(message.content)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            if !isUser { Spacer(minLength: 40) }
        }
    }
}
