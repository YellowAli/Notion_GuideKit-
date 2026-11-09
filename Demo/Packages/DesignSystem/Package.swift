// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "DesignSystem", targets: ["DesignSystem"])],
    dependencies: [.package(name: "GuideKit", path: "../../..")],
    targets: [
        .target(
            name: "DesignSystem",
            dependencies: [.product(name: "GuideKit", package: "GuideKit")],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
    ]
)
