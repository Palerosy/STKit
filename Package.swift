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
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.11/STKit.xcframework.zip",
            checksum: "82ee281518179277742f8b1c852e34f1e27572fbd1b469462eff8dc4930f1e2c"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.11/STDOCX.xcframework.zip",
            checksum: "f095ec18a1ad632b2d3a7a0f243123727089fc36719362597010f440b274f8cc"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.11/STExcel.xcframework.zip",
            checksum: "332fc2474672dd9f988f1f4e51b0cf295b8b22673c9fd145e60b5d48d3987d31"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.11/STTXT.xcframework.zip",
            checksum: "3297ff3ba679ef831240464a256860f76dd97aaba0687e23fc5b1a74bc017351"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.11/_ZIPFoundation.xcframework.zip",
            checksum: "7c6c0a8845a2a6ed459bfd5a04c264fb9d7011b66578e5356f2ab834ea589047"
        ),
    ]
)
