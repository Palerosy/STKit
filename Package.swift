// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "STKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "STKit", targets: ["STKit"]),
        .library(name: "STDOCX", targets: ["STDOCX", "STKit"]),
        .library(name: "STExcel", targets: ["STExcel", "STKit"]),
        .library(name: "STTXT", targets: ["STTXT", "STKit"]),
    ],
    targets: [
        .binaryTarget(
            name: "STKit",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STKit.xcframework.zip",
            checksum: "3510eb5670781ca458d72c060990e9b5f6071be4ae76587a0161857447b86e82"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STDOCX.xcframework.zip",
            checksum: "4a3dde3bfe7577d4c835649e8588cdc97cee977a20ace0d634df79a58299aaa9"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STExcel.xcframework.zip",
            checksum: "3e674bd5b8c9e61b7aa7125b5791d0f268ffc9a11b2f77dd1f294d1d29032d74"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STTXT.xcframework.zip",
            checksum: "0e7b9f21fa9920ded7d3c72f0d6aa3fd8aaa2c6fb0a97cef4a8e3f09efae1768"
        ),
    ]
)
