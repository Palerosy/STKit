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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.37/STKit.xcframework.zip", checksum: "b0fbd92f0bf816f32c4762e34a440fd315a127a32257923b5e159d5c353e97cb"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.37/STDOCX.xcframework.zip", checksum: "54219db5390dc628242eda7fe96164ea0dbb1225bf26dddd75148869698c908c"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.37/STExcel.xcframework.zip", checksum: "de1c024a815959a0c2503ee8474c7fd48318e45ea10ecd44bcd1ee2415a12c4a"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.37/STTXT.xcframework.zip", checksum: "3d6236a0a6d3eb3100ff27657753d671084c277ca31ff771cff36a8329bd2617"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.7.37/STPDF.xcframework.zip", checksum: "e06c5d2119791f837d0b6cc933f57a48584b4c765b6cca4b7e9f6486f0d3fb3a"),
    ]
)
