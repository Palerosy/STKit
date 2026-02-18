// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "STKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "STKit", targets: ["STKit"]),
        .library(name: "STDOCX", targets: ["STDOCX", "STKit", "_ZIPFoundation"]),
        .library(name: "STExcel", targets: ["STExcel", "STKit", "_ZIPFoundation"]),
        .library(name: "STTXT", targets: ["STTXT", "STKit"]),
    ],
    targets: [
        .binaryTarget(
            name: "STKit",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.1/STKit.xcframework.zip",
            checksum: "5a4cd9b6e904cb1a38898fc7d42bd088f0154a865ea3df8d27126b0dc1e71736"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.1/STDOCX.xcframework.zip",
            checksum: "5a3dd6acbee1731525220dc49f819754c603027e09cf32e03e405d513f9bc157"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.1/STExcel.xcframework.zip",
            checksum: "74321869d4e56c3d1013b8b6fc6d124421578cd125b42d2f7bbde683b03fa2f7"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.1/STTXT.xcframework.zip",
            checksum: "19df6d8c268feb82c77424c723bf366cd847a6eb8c353f8ed8d5ab8d87d89c82"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.1/_ZIPFoundation.xcframework.zip",
            checksum: "250fb19cbf6052145d550cea05cea4abf53d2540713ffcf7fafc3cb0758ae401"
        ),
    ]
)
