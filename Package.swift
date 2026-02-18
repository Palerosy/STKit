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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.28/STKit.xcframework.zip", checksum: "23a8e412aa7c6d0404be7fe2833bd872e058ec11d18450d945046b6aa08c5154"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.28/STDOCX.xcframework.zip", checksum: "52e33b47391973c33e4c0c36297690517e327f425179cf0da9e54533d3f3c8b2"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.28/STExcel.xcframework.zip", checksum: "7fa76b4f74ab856dc4be274907f901434d134e38d215a8d7a24df763c81e1b67"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.28/STTXT.xcframework.zip", checksum: "be45e9db1b69dd297203a08081d3ec418b08a70796a53cfb45bc8b2a0e3d6a96"),
    ]
)
