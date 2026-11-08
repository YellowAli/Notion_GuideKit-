// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "EditorFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "EditorFeature", targets: ["EditorFeature"])],
    dependencies: [
        .package(path: "../../.."),
        .package(path: "../DesignSystem"),
    ],
    targets: [
        .target(
            name: "EditorFeature",
            dependencies: [
                .product(name: "GuideKit", package: "Notion_GuideKit-"),
                "DesignSystem",
            ],
            resources: [.copy("Resources/flows")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "EditorFeatureTests",
            dependencies: ["EditorFeature"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
