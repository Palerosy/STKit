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
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.5/STKit.xcframework.zip",
            checksum: "cc056df4e78fcc7267fa60f1de939222cd379d191789bf899bee52ac3cec67b3"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.5/STDOCX.xcframework.zip",
            checksum: "2bc68c6a8c4e75c35ba4247632ce5304605e28ea20b7e0cdb4d0eeb7b013fc75"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.5/STExcel.xcframework.zip",
            checksum: "d151b584ee6af8fb42961144bfb4a3588459d116a4630ac172c0835ea45d8b75"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.5/STTXT.xcframework.zip",
            checksum: "3a288bb498586eb648e5a1919d337a599b638cfa29a1276430e9092a51b0b6dc"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.5/_ZIPFoundation.xcframework.zip",
            checksum: "2d8661d7d2a394e6dfd8344b8c02b7e5f09fdabb83d33708b7539b61044cfff3"
        ),
    ]
)
