// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GrowlAds",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "GrowlAds", targets: ["GrowlAds"]),
    ],
    targets: [
        .binaryTarget(
            name: "GrowlAds",
            url: "https://github.com/growlads/growl-ios-sdk/releases/download/1.0.0/GrowlAds.xcframework.zip",
            checksum: "CHECKSUM_PLACEHOLDER"
        ),
    ]
)
