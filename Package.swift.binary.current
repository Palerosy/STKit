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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.32/STKit.xcframework.zip", checksum: "d5b12e1528cd5d50b51a3b22266b43c484c05fb6b261aaaf745853fa96448913"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.32/STDOCX.xcframework.zip", checksum: "8896d10a56c6838cbea2373356571f62d7b98debba8f99d4b8a639caed8c2407"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.32/STExcel.xcframework.zip", checksum: "aa9b47e302f00163aac5a25cedb0b13a38c5ce6e17d74e4f5b422ef6d90ffe78"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.32/STTXT.xcframework.zip", checksum: "664cf6c7bcdd8aec9c241247f2afb69b6211e95a819daf3b331da8e368670f74"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.7.32/STPDF.xcframework.zip", checksum: "110c51010dbd04fe95c2e3165f35039c3982810baf8ab3470d382839055cc6bf"),
    ]
)
