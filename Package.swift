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
            url: "https://github.com/Palerosy/STKit/releases/download/0.3.0/STKit.xcframework.zip",
            checksum: "7b5ac4d473a71856718d2405f053102081c5531edd106262b285ddce77aa5df8"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.3.0/STDOCX.xcframework.zip",
            checksum: "56362daeef69dbdb0745e1912eae83efda239ab827c57d459c5512f621a53405"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.3.0/STExcel.xcframework.zip",
            checksum: "84b7d19d05ebc20a87110a2b3909076cd0ffdcb62e2aa74bcd4baad9d8ed934d"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.3.0/STTXT.xcframework.zip",
            checksum: "5a769f82d3601ec96aa5e30ff73ef9c3c84c2e8296d03ee871924bcefd0d27d1"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.3.0/_ZIPFoundation.xcframework.zip",
            checksum: "e819b96c7eb8a5c8b56938d9ab40c65c407b837d3c692c8f9dcc4d8293ebf3ce"
        ),
    ]
)
