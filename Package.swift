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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.41/STKit.xcframework.zip", checksum: "b837396947b1ae75c5dbf2872cef746773a39e1a3323f33b8c37348abf171730"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.41/STDOCX.xcframework.zip", checksum: "da52f2b04879b7206b9c58d616fea827120494a5442465a9001338c7bac3362a"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.41/STExcel.xcframework.zip", checksum: "299d60a203bfc21eead99af9d30e040fd9f77ed7028cb1c62df64a9e79f20391"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.41/STTXT.xcframework.zip", checksum: "893f972a1d7252b7dde28a728814586a19cb1174a397b33eb83f7273c9a9f6fe"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.7.41/STPDF.xcframework.zip", checksum: "50c8dea50ea10961998d299ad1e5de125b87eb22b6e3130732e1089b927c3645"),
    ]
)
