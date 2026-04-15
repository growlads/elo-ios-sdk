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
            url: "https://github.com/growlads/growl-ios-sdk/releases/download/0.0.1/GrowlAds.xcframework.zip",
            checksum: "b547fdc54fc31e7bd1083d7a450aae75b98e0a91ed9d7417e2de812111a5c6a9"
        ),
    ]
)
