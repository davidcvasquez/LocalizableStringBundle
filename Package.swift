// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LocalizableStringBundle",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15),
        .iOS(.v18)
    ],
    products: [
        .library(name: "LocalizableStringBundle", targets: ["LocalizableStringBundle"])
    ],
    dependencies: [
        .package(url: "https://github.com/davidcvasquez/LoggerCategories.git", from: "1.0.0"),
        .package(url: "https://github.com/davidcvasquez/CompactUUID.git", from: "1.1.1"),
        // DocC plugin (command plugin that adds `generate-documentation`)
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0")
    ],
    targets: [
        .target(
            name: "LocalizableStringBundle",
            dependencies: [
                .product(name: "LoggerCategories", package: "LoggerCategories"),
                .product(name: "CompactUUID", package: "CompactUUID")
            ],
            path: "Sources/LocalizableStringBundle",
            resources: [
                .process("Resources/Strings")
            ],
            swiftSettings: [
                 .defaultIsolation(MainActor.self)
            ]
        ),
        .testTarget(
            name: "LocalizableStringBundleTests",
            dependencies: [
	        "LocalizableStringBundle",
                .product(name: "LoggerCategories", package: "LoggerCategories"),
                .product(name: "CompactUUID", package: "CompactUUID")
            ],
            resources: [
                .process("Resources/Strings")
            ]
        )
    ]
)
