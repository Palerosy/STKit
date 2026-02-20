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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.31/STKit.xcframework.zip", checksum: "0ad7a4031966978a604c32cbb1c9c8fe94537fddaf714dd5636ecfa7f79423a4"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.31/STDOCX.xcframework.zip", checksum: "cbb283b2e5ce445b65b9f3ffe5d2799f52d7a60563eb3f06040f72c04a04cdd9"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.31/STExcel.xcframework.zip", checksum: "c90f61901c38db8fda233846d7821e854cc5d3e493cdebec9372784fa7c80636"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.31/STTXT.xcframework.zip", checksum: "24a8335a3904ad6ca272a94d3ed477432b26af189ec638e6c5a6c83d69e13158"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.7.31/STPDF.xcframework.zip", checksum: "447297e9e91779bcac9ad88fa8700e2e7feec269c1d9c9d439edb3a0825a26eb"),
    ]
)
