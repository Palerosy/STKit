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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.22/STKit.xcframework.zip", checksum: "be4e14d1f23cc301aa94e5ca10548b09b2e3d5f33b95e1b7732aee260154d5d8"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.22/STDOCX.xcframework.zip", checksum: "785931d75267a14d0cc1424fe4bf04832e3e37f350b649b28cecf7926f3de7d6"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.22/STExcel.xcframework.zip", checksum: "0a44ee4d26d60d641392f440dbfd9d4eb6dd2719ea2a9035f72483a32456c9c6"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.22/STTXT.xcframework.zip", checksum: "0e55bb2e4e935d902574367adc56ef6b5b0427c0e0d1503aa5a04d136e98f30f"),
    ]
)
