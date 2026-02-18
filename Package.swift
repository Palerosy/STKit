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
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.14/STKit.xcframework.zip",
            checksum: "8fee602e982a795c53371e558b7f3314b4bb1a6d1d90c423c2ddbe37840512f3"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.14/STDOCX.xcframework.zip",
            checksum: "b6d80abbbba1c0734918644a7074bba9df0c955ad9592e14c8cd9645003cf1c9"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.14/STExcel.xcframework.zip",
            checksum: "f5d59688c44e6c27dc0886ad37e7ed129f7db27c88e5c9062a9e14b8164df6dc"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.14/STTXT.xcframework.zip",
            checksum: "278ab4b0ad929c372867db13e0527756380adb5fb541c9e15a911034ede1a70a"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.14/_ZIPFoundation.xcframework.zip",
            checksum: "cba2ffe276005ea14e0e8c82408b97802fd4a378873a38c0533c0e99317c9749"
        ),
    ]
)
