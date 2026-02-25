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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.36/STKit.xcframework.zip", checksum: "a7fe60a937865b6df163b05367d1e9d711c149f0a01ee3b5c4f420542b6ac305"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.36/STDOCX.xcframework.zip", checksum: "369018cb79e673a7adf6537462ebf4412f533875a9c84ca2a08b6d174088a110"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.36/STExcel.xcframework.zip", checksum: "c27196f1381b2ac959cd7888ba687d43a89fb2a7da29f0500f1d423da7d3ca4c"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.36/STTXT.xcframework.zip", checksum: "25816d31b96e507a5bc5dc3c2908022983b678086f4d9fccb9467707ea84a495"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.7.36/STPDF.xcframework.zip", checksum: "0c47a837fccea901e0a64041c4b96d72f69d0b6d1ed2653d6b6019141b6ac41b"),
    ]
)
