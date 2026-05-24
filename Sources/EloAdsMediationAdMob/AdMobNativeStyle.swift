#if canImport(UIKit)
import UIKit

/// Deprecated UIKit-style overrides for AdMob native fills.
///
/// Presentation now lives on ``EloAdView``. Apply ``EloAdStyle`` with
/// `.eloAdStyle(...)` so Elo-direct and renderer-backed AdMob fills share
/// the same styling path.
@available(*, deprecated, message: "Use EloAdStyle on EloAdView via .eloAdStyle(...).")
public struct AdMobNativeStyle: @unchecked Sendable {
    public var cardBackground: UIColor?
    public var titleColor: UIColor?
    public var descriptionColor: UIColor?
    public var badgeColor: UIColor?
    public var borderColor: UIColor?
    public var borderWidth: CGFloat?
    public var cornerRadius: CGFloat?

    public init(
        cardBackground: UIColor? = nil,
        titleColor: UIColor? = nil,
        descriptionColor: UIColor? = nil,
        badgeColor: UIColor? = nil,
        borderColor: UIColor? = nil,
        borderWidth: CGFloat? = nil,
        cornerRadius: CGFloat? = nil
    ) {
        self.cardBackground = cardBackground
        self.titleColor = titleColor
        self.descriptionColor = descriptionColor
        self.badgeColor = badgeColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
    }

    public static let `default` = AdMobNativeStyle()
}
#endif
