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
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.1/STKit.xcframework.zip",
            checksum: "a4bc515788f8339c00ab4e55fe9c45471d3e41fd60533c5acc70b161d46add75"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.1/STDOCX.xcframework.zip",
            checksum: "a9403a898db31903f8323a474e80dee5c45090e438bbebebe3cfffbbde91ab8d"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.1/STExcel.xcframework.zip",
            checksum: "ab4861235d5e0b453c225213211c0a4b2d2f82ce8b24923588281a5df6a22234"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.1/STTXT.xcframework.zip",
            checksum: "3cc66c7adc56c7df0dea8c6fbe17787b188d7f21f20261edaac2aec9ee81ab53"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.1/_ZIPFoundation.xcframework.zip",
            checksum: "1cda4a5a577e0eb5e9951fcf131aaee338f3e06e8ee3f443e0f79404e3636ea7"
        ),
    ]
)
