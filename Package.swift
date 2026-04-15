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
            url: "https://github.com/growlads/growl-ios-sdk/releases/download/0.0.4/GrowlAds.xcframework.zip",
            checksum: "f2c61c949cc388afdb26a811b584e2ad4caa364907b85a894467056c3a8b284e"
        ),
    ]
)
