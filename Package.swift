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
        .library(name: "STPDF", targets: ["STPDF", "STKit"]),
    ],
    targets: [
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.35/STKit.xcframework.zip", checksum: "01cbe882bba355db356b501ea718b0f9d8ea1ec7a020f276a0b8f69eacc68256"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.35/STDOCX.xcframework.zip", checksum: "8f09c911bfa59023ac66df530e7b1c0f3ba1a021fe625be31be2776711181fe1"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.35/STExcel.xcframework.zip", checksum: "7e8f1b9d937a877c5ad4f2a6226eb5336165df9063f9ed89144ebfc53b459d20"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.35/STTXT.xcframework.zip", checksum: "4eeafaf46abb9fe076bb4194b750653e28f7c192bc0b11d8be879c86c68467b8"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.7.35/STPDF.xcframework.zip", checksum: "7c941145dde3024a02cc55f1952ac0c08f53890cfce55055fe1c9c76ddf89a03"),
    ]
)
