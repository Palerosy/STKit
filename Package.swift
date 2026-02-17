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
            url: "https://github.com/Palerosy/STKit/releases/download/0.4.0/STKit.xcframework.zip",
            checksum: "9148326233eb29bb7a26e7625ed85a3ca86173968c891a2c3ae8f5ab2b0f154b"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.4.0/STDOCX.xcframework.zip",
            checksum: "319eb4de83bc43bf2712067894ce6d5680c03647af0461243c408f456208531b"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.4.0/STExcel.xcframework.zip",
            checksum: "91465d845358687756d6422f584434adb1a2c560d56ad93822ed47320d112c45"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.4.0/STTXT.xcframework.zip",
            checksum: "7ec2adf04692d40a223ffed6f14cb26069ba49a35f68bfcb681e8cfb1d1965c8"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.4.0/_ZIPFoundation.xcframework.zip",
            checksum: "8c9441761ff8d43c0824eeafab2c5c26ad4fc87cc5e36fc730a5d7d0923744bb"
        ),
    ]
)
