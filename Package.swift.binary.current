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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.24/STKit.xcframework.zip", checksum: "ee01f69a6e6a8cf5fb66527f2bbea209baaa976c11391cf763a9030d1600b0b4"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.24/STDOCX.xcframework.zip", checksum: "f541559376137ad13aae79937c956300cd62852392151591ed1e2de0a600d9db"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.24/STExcel.xcframework.zip", checksum: "eee3cd35efe0e473f8e1042e7452175d2122b963b26ed48a4d11b7408b8a4c39"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.24/STTXT.xcframework.zip", checksum: "d1184c28fb8c85ae47d5b7b664da9889e7ec644444ba6552e4d44a3f4ddc2c71"),
    ]
)
