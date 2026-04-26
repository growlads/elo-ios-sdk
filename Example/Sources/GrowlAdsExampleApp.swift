import SwiftUI
import GrowlAds

// Public test credentials — safe to commit; replace with your own once
// you're integrating into a real app.
private enum DemoConfig {
    static let publisherID = "68ee16873fd62ca79e1f7099"
    static let adUnitID    = "696f6a52f62c75af4a29f8ad"
}

@main
struct GrowlAdsExampleApp: App {
    init() {
        Growl.initialize(
            publisherId: DemoConfig.publisherID,
            adUnitId: DemoConfig.adUnitID
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
            Text("Growl Ads Demo")
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

            // GrowlAdView renders the loaded ad and hides itself on
            // `.noFill` / `.error`, so handing it the result directly is
            // the path of least resistance.
            GrowlAdView(result: adResult)
                .padding(.horizontal)

            // Surface the raw outcome so the demo is informative even when
            // there's no fill. A real app would just trust GrowlAdView's
            // built-in behavior and skip this.
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
