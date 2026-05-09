import Foundation

/// Internal pairing of an AdMob ad unit with the eCPM the adapter reports
/// when that unit fills.
///
/// The public ``AdMobNetworkAdapter`` API takes a single `adUnitId`; this
/// type exists so the internal waterfall machinery can keep its current
/// shape and so future SDK-side experiments (server-driven tiers, A/B-tuned
/// floors) have a place to land without changing publisher integration code.
struct AdMobPriceTier: Sendable, Equatable {
    /// AdMob native ad unit id, e.g. `"ca-app-pub-3940256099942544/3986624511"`.
    let adUnitId: String

    /// Bid value reported to Elo's mediator when this tier fills.
    let eCpm: Double
}
