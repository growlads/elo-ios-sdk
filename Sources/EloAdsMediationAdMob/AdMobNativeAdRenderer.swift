import Foundation
import EloAds

#if canImport(GoogleMobileAds) && canImport(UIKit)
import UIKit
@preconcurrency import GoogleMobileAds

/// Renders an AdMob native fill inside the SDK's SwiftUI `EloAdView` surface
/// while keeping AdMob's required `NativeAdView` asset ownership intact.
@MainActor
final class AdMobNativeAdRenderer: AdRenderer, @unchecked Sendable {
    private let nativeAd: NativeAd
    private let delegateBridge: AdMobNativeAdDelegateBridge
    private let style: AdMobNativeStyle
    private let layout: AdMobNativeLayout
    private let sponsoredLabel: String

    var minimumDisplayHeight: CGFloat {
        switch layout {
        case .compactHorizontal: return 116
        case .heroCard:          return 240
        }
    }

    init(
        nativeAd: NativeAd,
        delegateBridge: AdMobNativeAdDelegateBridge,
        style: AdMobNativeStyle = .default,
        layout: AdMobNativeLayout = .compactHorizontal,
        sponsoredLabel: String = "Sponsored"
    ) {
        self.nativeAd = nativeAd
        self.delegateBridge = delegateBridge
        self.style = style
        self.layout = layout
        self.sponsoredLabel = sponsoredLabel
    }

    func makeView() -> AnyObject {
        let host = AdMobNativeHostView(
            style: style,
            layout: layout,
            sponsoredLabel: sponsoredLabel
        )
        nativeAd.delegate = delegateBridge
        host.bind(nativeAd: nativeAd)
        return host
    }

    func update(_ view: AnyObject) {
        guard let host = view as? AdMobNativeHostView else { return }
        host.bind(nativeAd: nativeAd)
    }
}

@MainActor
final class AdMobNativeHostView: NativeAdView {
    private let layout: AdMobNativeLayout
    private let sponsoredLabelView = UILabel()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let mediaAssetView = MediaView()
    private let iconAssetView = UIImageView()
    private let assetContainer = UIView()
    private let textStack = UIStackView()
    private let contentStack = UIStackView()
    private let rootStack = UIStackView()

    init(
        style: AdMobNativeStyle,
        layout: AdMobNativeLayout,
        sponsoredLabel: String
    ) {
        self.layout = layout
        super.init(frame: .zero)

        configureContainer(style: style)
        configureSponsoredLabel(sponsoredLabel)
        configureAssetViews()
        configureTextLabels(style: style)
        configureLayout(layout: layout)
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

        callToActionView = nil
        self.nativeAd = nativeAd
    }

    private func configureContainer(style: AdMobNativeStyle) {
        backgroundColor = style.cardBackground ?? .systemBackground
        layer.cornerRadius = style.cornerRadius ?? 12
        layer.cornerCurve = .continuous
        clipsToBounds = true
        layer.borderColor = (style.borderColor ?? UIColor.separator).cgColor
        layer.borderWidth = style.borderWidth ?? 1
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    private func configureSponsoredLabel(_ text: String) {
        sponsoredLabelView.text = text.uppercased()
        sponsoredLabelView.font = .systemFont(ofSize: 11, weight: .semibold)
        sponsoredLabelView.textAlignment = .left
        sponsoredLabelView.textColor = .secondaryLabel
        sponsoredLabelView.backgroundColor = .clear
        sponsoredLabelView.numberOfLines = 1
        sponsoredLabelView.setContentCompressionResistancePriority(.required, for: .vertical)
        sponsoredLabelView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func configureAssetViews() {
        assetContainer.translatesAutoresizingMaskIntoConstraints = false
        assetContainer.clipsToBounds = true
        assetContainer.layer.cornerRadius = 10
        assetContainer.layer.cornerCurve = .continuous
        assetContainer.backgroundColor = .secondarySystemBackground
        assetContainer.layer.borderColor = UIColor.separator.cgColor
        assetContainer.layer.borderWidth = 1

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

    private func configureTextLabels(style: AdMobNativeStyle) {
        headlineLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        headlineLabel.textColor = style.titleColor ?? .label
        headlineLabel.numberOfLines = 2
        headlineLabel.lineBreakMode = .byTruncatingTail
        headlineLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        headlineLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = style.descriptionColor ?? .secondaryLabel
        bodyLabel.numberOfLines = 2
        bodyLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    private func configureLayout(layout: AdMobNativeLayout) {
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 5
        textStack.addArrangedSubview(headlineLabel)
        textStack.addArrangedSubview(bodyLabel)
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        contentStack.axis = layout == .compactHorizontal ? .horizontal : .vertical
        contentStack.alignment = .top
        contentStack.spacing = 14
        contentStack.distribution = .fill
        contentStack.addArrangedSubview(assetContainer)
        contentStack.addArrangedSubview(textStack)

        rootStack.axis = .vertical
        rootStack.alignment = .fill
        rootStack.spacing = 8
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        rootStack.addArrangedSubview(sponsoredLabelView)
        rootStack.addArrangedSubview(contentStack)
        addSubview(rootStack)

        let assetSize: CGFloat = layout == .compactHorizontal ? 72 : 160
        let constraints = [
            rootStack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            rootStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -14),

            assetContainer.widthAnchor.constraint(equalToConstant: assetSize),
            assetContainer.heightAnchor.constraint(equalToConstant: assetSize),
        ]

        NSLayoutConstraint.activate(constraints)

        if layout == .heroCard {
            assetContainer.widthAnchor.constraint(equalTo: contentStack.widthAnchor).isActive = true
        }
    }

    private func registerVisibleAssetViews() {
        headlineView = headlineLabel
        bodyView = bodyLabel
        callToActionView = nil
    }
}

#endif
