// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TeXSplit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TeXSplit", targets: ["TeXSplit"])
    ],
    targets: [
        .target(
            name: "TeXSplit",
            path: "TeXSplit",
            exclude: ["App", "Resources/Assets.xcassets", "Resources/TeXLive"]
        ),
        .testTarget(
            name: "TeXSplitTests",
            dependencies: ["TeXSplit"],
            path: "TeXSplitTests"
        )
    ]
)
