// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GuideKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "GuideKitCore", targets: ["GuideKitCore"]),
        .library(name: "GuideKit", targets: ["GuideKit"]),
        .library(name: "GuideKitTesting", targets: ["GuideKitTesting"]),
    ],
    targets: [
        .target(name: "GuideKitCore", swiftSettings: [.swiftLanguageMode(.v5)]),
        .target(name: "GuideKit", dependencies: ["GuideKitCore"], swiftSettings: [.swiftLanguageMode(.v5)]),
        .target(name: "GuideKitTesting", dependencies: ["GuideKit"], swiftSettings: [.swiftLanguageMode(.v5)]),
        .testTarget(name: "GuideKitCoreTests", dependencies: ["GuideKitCore"], swiftSettings: [.swiftLanguageMode(.v5)]),
        .testTarget(name: "GuideKitTests", dependencies: ["GuideKit"], swiftSettings: [.swiftLanguageMode(.v5)]),
    ]
)
