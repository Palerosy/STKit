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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.16/STKit.xcframework.zip", checksum: "8e424b7e6331240577a53e00e6b0d3bdb1b10a4985f67d495f8a9b2278a1ccd6"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.16/STDOCX.xcframework.zip", checksum: "65164d7e09d30ad4090cc91448d4791bedd6c0d5c6fceb4d42fbbe4b451853e0"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.16/STExcel.xcframework.zip", checksum: "e0e6e8c0fb734483e523bdb65401bff970c3ee3e9fb90979f620f8323ca39f6b"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.16/STTXT.xcframework.zip", checksum: "60fca11914bbfdfef14fd76569e5936dfa552e55971c62a7759749a7bf08b2c5"),
    ]
)
