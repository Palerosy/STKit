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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.20/STKit.xcframework.zip", checksum: "5817945f00392d672d54c5d929dca7f6a74138c0dfc894410d8df3df9b6c3669"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.20/STDOCX.xcframework.zip", checksum: "94001e7e6b3fa4034352373d9d4ff355a37b4496fa439b8a13496907ba855178"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.20/STExcel.xcframework.zip", checksum: "cf0810dc8a1e573e23f366c66adbbe47cb8ca256d9b79c4f095e52d418896b14"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.20/STTXT.xcframework.zip", checksum: "aa7b194bcf0e9ec267e912f57afb1b72b0af3aa4715ddb7cf88efc5838a6227b"),
    ]
)
