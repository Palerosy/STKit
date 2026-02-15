// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "STKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "STKit", targets: ["STKit"]),
        .library(name: "STDOCX", targets: ["STDOCX"]),
        .library(name: "STExcel", targets: ["STExcel"]),
        .library(name: "STTXT", targets: ["STTXT"]),
    ],
    dependencies: [
        .package(path: "Packages/SwiftDocX"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "STKit",
            dependencies: [],
            resources: [.process("Resources")]
        ),
        .target(
            name: "STDOCX",
            dependencies: ["STKit", "SwiftDocX"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "STExcel",
            dependencies: ["STKit", "ZIPFoundation"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "STTXT",
            dependencies: ["STKit"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "STKitTests",
            dependencies: ["STKit"]
        ),
        .testTarget(
            name: "STDOCXTests",
            dependencies: ["STDOCX"]
        ),
        .testTarget(
            name: "STExcelTests",
            dependencies: ["STExcel"]
        ),
        .testTarget(
            name: "STTXTTests",
            dependencies: ["STTXT"]
        ),
    ]
)
