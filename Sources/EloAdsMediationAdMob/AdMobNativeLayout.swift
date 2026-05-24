import Foundation

/// Deprecated visual treatment for AdMob native ads.
///
/// Presentation now lives on ``EloAdView``. Use ``EloAdLayout`` via
/// `EloAdView(..., layout:)` or `.eloAdLayout(...)`.
@available(*, deprecated, message: "Use EloAdLayout on EloAdView or .eloAdLayout(...).")
public enum AdMobNativeLayout: Sendable, Hashable, CaseIterable {
    /// App icon on the leading edge with headline + body
    /// stacked to its trailing side. Card height stays roughly constant
    /// across creatives, which keeps SwiftUI feeds (`LazyVStack`, `List`)
    /// from jittering when a new auction delivers an ad with a different
    /// aspect ratio.
    case compactHorizontal

    /// `MediaView` spans the full card width with its height driven by
    /// `mediaContent.aspectRatio`. Headline and body stack vertically below
    /// the media. Best for surfaces where the creative deserves real
    /// estate (e.g. a dedicated slot under the assistant response, a
    /// "promoted" card in a feed).
    case heroCard
}
