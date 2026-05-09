import Foundation
import EloAds

struct AdMobNativeAssets: Sendable, Equatable {
    let identifier: String
    let headline: String?
    let body: String?
    let imageURL: String?
}

enum AdMobCreativeMapper {
    static func makeCreative(
        from assets: AdMobNativeAssets,
        tracker: some AdTracker,
        renderer: AdRenderer?
    ) -> EloAd? {
        guard let headline = assets.headline, !headline.isEmpty else {
            return nil
        }

        return EloAd(
            id: assets.identifier,
            title: headline,
            description: assets.body,
            imageUrl: assets.imageURL,
            tracker: tracker,
            renderer: renderer
        )
    }
}
