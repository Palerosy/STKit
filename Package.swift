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
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.4/STKit.xcframework.zip",
            checksum: "462356b1a30a48a8c2e38caaefdcb4fb107c877382728f1d29744559f9a2c0a8"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.4/STDOCX.xcframework.zip",
            checksum: "d50d2aad5ad9255635c7b9d2902f2b0a1ea25b722e3ca73f77cf9e48c13fba55"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.4/STExcel.xcframework.zip",
            checksum: "c235cc0d97b3ab8977b9b23bcf8d4a7937a994f584b0b25046bbe05ce8bd86d1"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.4/STTXT.xcframework.zip",
            checksum: "f3f255119061e539214c3b675a8f4b1882b85ab7d4854165a23f6ff7e2eafbf8"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.4/_ZIPFoundation.xcframework.zip",
            checksum: "6c5635b48be8d795169bc02b0776ec2dba059a8a6cdbcc323d1b1ff0d6b6ec7a"
        ),
    ]
)
