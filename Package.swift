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
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.6/STKit.xcframework.zip",
            checksum: "96c26b57f4465fbdeeafbdfbbb8836ca703ff7ac7b4b182ddf2f836f6d266334"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.6/STDOCX.xcframework.zip",
            checksum: "f3649ce437f5ba0711dc2597e9a9dc8f1543c551fda2b998a752796219ea516c"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.6/STExcel.xcframework.zip",
            checksum: "f8cc68150437dfb90f78aabd0b2d11caeb554f630dc9e99f34c257734599bf96"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.6/STTXT.xcframework.zip",
            checksum: "527b7b788f8ce2c0625791adae20e1d726413d7963098b9c08b11e4e2c092770"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.6/_ZIPFoundation.xcframework.zip",
            checksum: "6772c9ca342675e44b880b5925bf28b49d1e3262aa31a55726335a6f80a6bfd6"
        ),
    ]
)
