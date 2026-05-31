import Foundation
import EloAds

#if canImport(GoogleMobileAds) && canImport(UIKit)
import SwiftUI
import UIKit
@preconcurrency import GoogleMobileAds

/// Renders an AdMob native fill inside the SDK's SwiftUI `EloAdView` surface
/// while keeping AdMob's required `NativeAdView` asset ownership intact.
@MainActor
final class AdMobNativeAdRenderer: AdRenderer, @unchecked Sendable {
    private let nativeAd: NativeAd
    private let delegateBridge: AdMobNativeAdDelegateBridge

    var minimumDisplayHeight: CGFloat {
        minimumDisplayHeight(configuration: .init())
    }

    init(
        nativeAd: NativeAd,
        delegateBridge: AdMobNativeAdDelegateBridge
    ) {
        self.nativeAd = nativeAd
        self.delegateBridge = delegateBridge
    }

    func makeView() -> AnyObject {
        makeView(configuration: .init())
    }

    func minimumDisplayHeight(configuration: EloAdRenderConfiguration) -> CGFloat {
        switch configuration.layout {
        case .compactHorizontal: return 112
        case .heroCard:          return 240
        }
    }

    func makeView(configuration: EloAdRenderConfiguration) -> AnyObject {
        let host = AdMobNativeHostView(
            configuration: configuration
        )
        nativeAd.delegate = delegateBridge
        return host
    }

    func update(_ view: AnyObject) {
        guard let host = view as? AdMobNativeHostView else { return }
        host.bind(nativeAd: nativeAd)
    }
}

@MainActor
final class AdMobNativeHostView: NativeAdView {
    private enum Metrics {
        static let cardPadding: CGFloat = 12
        static let verticalSpacing: CGFloat = 10
        static let contentSpacing: CGFloat = 12
        static let textSpacing: CGFloat = 4
        static let compactAssetSize: CGFloat = 56
        static let heroAssetHeight: CGFloat = 160
        static let callToActionMinWidth: CGFloat = 88
        static let callToActionHeight: CGFloat = 44
        static let callToActionHorizontalPadding: CGFloat = 14
        static let adChoicesSize: CGFloat = 24
        static let cardCornerRadius: CGFloat = 12
        static let assetCornerRadius: CGFloat = 6
        static let sponsoredKern: CGFloat = 0.8
    }

    private let layout: EloAdLayout
    private let sponsoredLabelView = UILabel()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let callToActionButton = PaddedButton(type: .system)
    private let adChoicesAssetView = AdChoicesView()
    private let mediaAssetView = MediaView()
    private let iconAssetView = UIImageView()
    private let assetContainer = UIView()
    private let textStack = UIStackView()
    private let contentStack = UIStackView()
    private let rootStack = UIStackView()

    init(
        configuration: EloAdRenderConfiguration
    ) {
        self.layout = configuration.layout
        super.init(frame: .zero)

        configureContainer(style: configuration.style)
        accessibilityHint = configuration.openLinkAccessibilityLabel
        configureSponsoredLabel(configuration.sponsoredLabel, style: configuration.style)
        configureAssetViews()
        configureTextLabels(style: configuration.style)
        configureCallToActionButton(style: configuration.style)
        configureLayout(layout: configuration.layout)
        registerVisibleAssetViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("AdMobNativeHostView is created programmatically")
    }

    func bind(nativeAd: NativeAd) {
        headlineLabel.text = nativeAd.headline
        headlineLabel.isHidden = nativeAd.headline?.isEmpty ?? true

        bodyLabel.text = nativeAd.body
        bodyLabel.isHidden = nativeAd.body?.isEmpty ?? true
        let callToAction = nativeAd.callToAction?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasCallToAction = !(callToAction?.isEmpty ?? true)
        callToActionButton.setTitle(callToAction, for: .normal)
        callToActionButton.isHidden = !hasCallToAction

        switch layout {
        case .compactHorizontal:
            iconAssetView.image = nativeAd.icon?.image ?? nativeAd.images?.first?.image
            iconAssetView.isHidden = false
            mediaAssetView.isHidden = true
            mediaView = nil
            iconView = iconAssetView
        case .heroCard:
            mediaAssetView.mediaContent = nativeAd.mediaContent
            mediaAssetView.isHidden = false
            iconAssetView.isHidden = true
            mediaView = mediaAssetView
            iconView = nil
        }

        callToActionView = hasCallToAction ? callToActionButton : nil
        adChoicesView = adChoicesAssetView
        self.nativeAd = nativeAd
        bringSubviewToFront(adChoicesAssetView)
    }

    private func configureContainer(style: EloAdStyle) {
        backgroundColor = Self.uiColor(style.cardBackground, fallback: .secondarySystemBackground)
        layer.cornerRadius = style.cornerRadius ?? Metrics.cardCornerRadius
        layer.cornerCurve = .continuous
        clipsToBounds = true
        layer.borderColor = Self.uiColor(style.borderColor, fallback: .separator).cgColor
        layer.borderWidth = style.borderWidth ?? 1
    }

    private func configureSponsoredLabel(_ text: String, style: EloAdStyle) {
        let font = UIFont.systemFont(ofSize: 11, weight: .bold)
        sponsoredLabelView.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .kern: Metrics.sponsoredKern,
            ]
        )
        sponsoredLabelView.font = font
        sponsoredLabelView.textAlignment = .left
        sponsoredLabelView.textColor = Self.uiColor(style.badgeColor, fallback: .secondaryLabel)
        sponsoredLabelView.backgroundColor = .clear
        sponsoredLabelView.numberOfLines = 1
        sponsoredLabelView.setContentCompressionResistancePriority(.required, for: .vertical)
        sponsoredLabelView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureAssetViews() {
        assetContainer.translatesAutoresizingMaskIntoConstraints = false
        assetContainer.clipsToBounds = true
        assetContainer.layer.cornerRadius = Metrics.assetCornerRadius
        assetContainer.layer.cornerCurve = .continuous
        assetContainer.backgroundColor = .tertiarySystemBackground

        mediaAssetView.translatesAutoresizingMaskIntoConstraints = false
        mediaAssetView.backgroundColor = .tertiarySystemBackground
        mediaAssetView.contentMode = .scaleAspectFill

        iconAssetView.translatesAutoresizingMaskIntoConstraints = false
        iconAssetView.backgroundColor = .tertiarySystemBackground
        iconAssetView.contentMode = .scaleAspectFill
        iconAssetView.clipsToBounds = true

        assetContainer.addSubview(mediaAssetView)
        assetContainer.addSubview(iconAssetView)
        NSLayoutConstraint.activate([
            mediaAssetView.topAnchor.constraint(equalTo: assetContainer.topAnchor),
            mediaAssetView.leadingAnchor.constraint(equalTo: assetContainer.leadingAnchor),
            mediaAssetView.trailingAnchor.constraint(equalTo: assetContainer.trailingAnchor),
            mediaAssetView.bottomAnchor.constraint(equalTo: assetContainer.bottomAnchor),

            iconAssetView.topAnchor.constraint(equalTo: assetContainer.topAnchor),
            iconAssetView.leadingAnchor.constraint(equalTo: assetContainer.leadingAnchor),
            iconAssetView.trailingAnchor.constraint(equalTo: assetContainer.trailingAnchor),
            iconAssetView.bottomAnchor.constraint(equalTo: assetContainer.bottomAnchor),
        ])
    }

    private func configureTextLabels(style: EloAdStyle) {
        headlineLabel.font = .systemFont(ofSize: 15, weight: .bold)
        headlineLabel.textColor = Self.uiColor(style.titleColor, fallback: .label)
        headlineLabel.numberOfLines = 1
        headlineLabel.lineBreakMode = .byTruncatingTail
        headlineLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        headlineLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = Self.uiColor(style.descriptionColor, fallback: .secondaryLabel)
        bodyLabel.numberOfLines = 2
        bodyLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func configureCallToActionButton(style: EloAdStyle) {
        callToActionButton.horizontalPadding = Metrics.callToActionHorizontalPadding
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .bold)
        callToActionButton.titleLabel?.lineBreakMode = .byTruncatingTail
        callToActionButton.setTitleColor(
            Self.uiColor(style.callToActionForeground, fallback: .tintColor),
            for: .normal
        )
        callToActionButton.backgroundColor = Self.uiColor(
            style.callToActionBackground,
            fallback: UIColor.tintColor.withAlphaComponent(0.18)
        )
        callToActionButton.layer.cornerRadius = Metrics.callToActionHeight / 2
        callToActionButton.layer.cornerCurve = .continuous
        callToActionButton.isHidden = true
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        callToActionButton.setContentHuggingPriority(.required, for: .horizontal)
        callToActionButton.minimumHeight = Metrics.callToActionHeight
        NSLayoutConstraint.activate([
            callToActionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: Metrics.callToActionMinWidth),
            callToActionButton.heightAnchor.constraint(equalToConstant: Metrics.callToActionHeight),
        ])
    }

    private func configureLayout(layout: EloAdLayout) {
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = Metrics.textSpacing
        textStack.addArrangedSubview(headlineLabel)
        textStack.addArrangedSubview(bodyLabel)
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        contentStack.axis = layout == .compactHorizontal ? .horizontal : .vertical
        contentStack.alignment = layout == .compactHorizontal ? .center : .top
        contentStack.spacing = Metrics.contentSpacing
        contentStack.distribution = .fill
        contentStack.addArrangedSubview(assetContainer)
        contentStack.addArrangedSubview(textStack)
        contentStack.addArrangedSubview(callToActionButton)

        rootStack.axis = .vertical
        rootStack.alignment = .fill
        rootStack.spacing = Metrics.verticalSpacing
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        rootStack.addArrangedSubview(sponsoredLabelView)
        rootStack.addArrangedSubview(contentStack)
        addSubview(rootStack)
        adChoicesAssetView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(adChoicesAssetView)

        var constraints = [
            rootStack.topAnchor.constraint(equalTo: topAnchor, constant: Metrics.cardPadding),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Metrics.cardPadding),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Metrics.cardPadding),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -Metrics.cardPadding),

            adChoicesAssetView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            adChoicesAssetView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            adChoicesAssetView.widthAnchor.constraint(equalToConstant: Metrics.adChoicesSize),
            adChoicesAssetView.heightAnchor.constraint(equalToConstant: Metrics.adChoicesSize),
        ]

        switch layout {
        case .compactHorizontal:
            constraints.append(contentsOf: [
                assetContainer.widthAnchor.constraint(equalToConstant: Metrics.compactAssetSize),
                assetContainer.heightAnchor.constraint(equalToConstant: Metrics.compactAssetSize),
            ])
        case .heroCard:
            constraints.append(contentsOf: [
                assetContainer.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
                assetContainer.heightAnchor.constraint(equalToConstant: Metrics.heroAssetHeight),
            ])
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func registerVisibleAssetViews() {
        headlineView = headlineLabel
        bodyView = bodyLabel
        callToActionView = nil
        adChoicesView = adChoicesAssetView
    }

    private static func uiColor(_ color: Color?, fallback: UIColor) -> UIColor {
        guard let color else { return fallback }
        return UIColor(color)
    }
}

private final class PaddedButton: UIButton {
    var horizontalPadding: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    var minimumHeight: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        let titleSize = titleLabel?.intrinsicContentSize ?? super.intrinsicContentSize
        let superSize = super.intrinsicContentSize
        return CGSize(
            width: titleSize.width + horizontalPadding * 2,
            height: max(titleSize.height, superSize.height, minimumHeight)
        )
    }
}

#endif
