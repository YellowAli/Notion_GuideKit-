// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CalendarFeature",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "CalendarFeature", targets: ["CalendarFeature"])],
    dependencies: [
        .package(name: "GuideKit", path: "../../.."),
        .package(path: "../DesignSystem"),
    ],
    targets: [
        .target(
            name: "CalendarFeature",
            dependencies: [
                .product(name: "GuideKit", package: "GuideKit"),
                "DesignSystem",
            ],
            resources: [.copy("Resources/flows")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "CalendarFeatureTests",
            dependencies: ["CalendarFeature"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
