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

/// Which ad format a chat demonstrates once you open it.
private enum AdFormat: Hashable {
    /// A banner strip rendered inline in the message feed (`.inlineBanner`).
    case inlineBanner
    /// A banner pinned above the keyboard while the composer is focused
    /// (`.eloKeyboardBannerAd(messages:)`).
    case keyboardBanner

    var title: String {
        switch self {
        case .inlineBanner:   "Inline banner"
        case .keyboardBanner: "Keyboard banner"
        }
    }

    var blurb: String {
        switch self {
        case .inlineBanner:   "Renders in the message feed"
        case .keyboardBanner: "Pins above the keyboard — tap the composer"
        }
    }
}

/// A demo conversation plus the ad format it shows.
private struct Chat: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let messages: [ChatMessage]
    let format: AdFormat

    var preview: String { messages.last?.content ?? "" }
}

/// Root: a list of chats. Opening one shows its conversation and the ad
/// format it demonstrates.
struct ContentView: View {
    private let chats: [Chat] = [
        Chat(
            title: "Marathon training",
            messages: [
                ChatMessage(role: .user, content: "What's the best running shoe for marathon training?"),
                ChatMessage(role: .assistant, content: "For marathon training, you'll want shoes with good cushioning and durability. Brands like Hoka, Nike, and Brooks are popular picks."),
            ],
            format: .inlineBanner
        ),
        Chat(
            title: "Home espresso",
            messages: [
                ChatMessage(role: .user, content: "How do I make espresso at home without a fancy machine?"),
                ChatMessage(role: .assistant, content: "A stovetop Moka pot gets you close for very little money. Use fine ground coffee, medium heat, and pull it off the stove as soon as it starts sputtering."),
            ],
            format: .keyboardBanner
        ),
    ]

    var body: some View {
        NavigationStack {
            List(chats) { chat in
                NavigationLink(value: chat) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chat.title).font(.headline)
                        Text(chat.preview)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Text(chat.format.title)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle("Chats")
            .navigationDestination(for: Chat.self) { chat in
                ChatDetailView(chat: chat)
            }
        }
    }
}

/// A single conversation. Depending on the chat's format it renders either an
/// inline banner in the feed or a banner pinned above the keyboard.
private struct ChatDetailView: View {
    let chat: Chat

    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(chat.format.blurb)
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    ForEach(chat.messages, id: \.self) { message in
                        ChatBubble(message: message)
                    }

                    // Inline banner renders in the feed. The keyboard-banner
                    // chat shows its ad via the modifier below instead.
                    if chat.format == .inlineBanner {
                        EloAdView(messages: chat.messages, layout: .inlineBanner)
                    }
                }
                .padding()
            }

            composer
        }
        .navigationTitle(chat.title)
        .navigationBarTitleDisplayMode(.inline)
        // `.eloKeyboardBannerAd` pins the inline banner above the keyboard with
        // a single modifier — no keyboard tracking in the host app. It only
        // appears while the composer is focused, so it's applied to the whole
        // screen for the keyboard-banner chat.
        .keyboardBanner(for: chat)
    }

    private var composer: some View {
        HStack(spacing: 8) {
            TextField("Message", text: $draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            Button {
                draft = ""
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(.bar)
    }
}

private extension View {
    /// Applies the keyboard-banner modifier only for keyboard-banner chats,
    /// leaving inline-banner chats untouched.
    @ViewBuilder
    func keyboardBanner(for chat: Chat) -> some View {
        if chat.format == .keyboardBanner {
            self.eloKeyboardBannerAd(messages: chat.messages)
        } else {
            self
        }
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
