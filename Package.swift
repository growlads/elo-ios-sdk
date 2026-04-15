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
            url: "https://github.com/growlads/growl-ios-sdk/releases/download/0.0.3/GrowlAds.xcframework.zip",
            checksum: "d78880a6a43a9431c791b7d71891da5cfaeb0fea244444c95a3f83a303562cbc"
        ),
    ]
)
