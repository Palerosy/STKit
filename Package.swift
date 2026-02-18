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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.25/STKit.xcframework.zip", checksum: "9d91581cc2ed8636032414c5f5d4e2bedfb24957c00682a852e97f27b2f52979"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.25/STDOCX.xcframework.zip", checksum: "bbfeb52419e1e5f7107e6862df5bcfccb460d377cc505d34fbc2b4612731f970"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.25/STExcel.xcframework.zip", checksum: "77386099acb47e3efe6e24fdc3765f486bc371b3a644776f5229380a194a2340"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.25/STTXT.xcframework.zip", checksum: "149e2697360f78153e7931680422673ca9b420efee3a54e9a58e0986d0c6ef06"),
    ]
)
