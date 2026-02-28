// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "STKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "STKit", targets: ["STKit"]),
        .library(name: "STDOCX", targets: ["STDOCX", "STKit"]),
        .library(name: "STExcel", targets: ["STExcel", "STKit"]),
        .library(name: "STTXT", targets: ["STTXT", "STKit"]),
        .library(name: "STPDF", targets: ["STPDF", "STKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "STKit",
            dependencies: [],
            path: "Sources/STKit",
            resources: [.process("Resources")]
        ),
        .target(
            name: "STPDF",
            dependencies: ["STKit"],
            path: "Sources/STPDF",
            resources: [.process("Resources")]
        ),
        .target(
            name: "STDOCX",
            dependencies: ["STKit", .product(name: "ZIPFoundation", package: "ZIPFoundation")],
            path: "Sources/STDOCX",
            resources: [.process("Resources")]
        ),
        .target(
            name: "STExcel",
            dependencies: ["STKit", .product(name: "ZIPFoundation", package: "ZIPFoundation")],
            path: "Sources/STExcel",
            resources: [.process("Resources")]
        ),
        .target(
            name: "STTXT",
            dependencies: ["STKit"],
            path: "Sources/STTXT",
            resources: [.process("Resources")]
        ),
    ]
)
