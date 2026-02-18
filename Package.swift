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
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.3/STKit.xcframework.zip",
            checksum: "5928a9a936840ca5f609fbf1301deadf641be8cdd2b0d41e1a21379d3f97f879"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.3/STDOCX.xcframework.zip",
            checksum: "0a0361636b9c5fc619689c81fd407fdfd7a0c96963ecd0e0efb09778e6964a3d"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.3/STExcel.xcframework.zip",
            checksum: "fb0723e90c8ea5605dceb71d6c0c1ef5922ac3152b4b681e13ee2d8d33155fbb"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.3/STTXT.xcframework.zip",
            checksum: "1a94d6195b0448bdf659e3ab0a74a3fff4dee34830dac9df0c5c58c0567fd21c"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.3/_ZIPFoundation.xcframework.zip",
            checksum: "4d57ae6c8afd7698c8013716449056ff7bc1a69ab0ff3b730d8e4e477e7b445d"
        ),
    ]
)
