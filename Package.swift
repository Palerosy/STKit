// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "STKit",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "STKit", targets: ["STKit"]),
        .library(name: "STDOCX", targets: ["STDOCX", "STKit"]),
        .library(name: "STExcel", targets: ["STExcel", "STKit", "ZIPFoundation"]),
        .library(name: "STTXT", targets: ["STTXT", "STKit"]),
        .library(name: "STPDF", targets: ["STPDF", "STKit"]),
    ],
    targets: [
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.9.3/STKit.xcframework.zip", checksum: "b0b28b81e7ee6ec5f2062fb14325a0898f7e7b95d277069551f31a4fec63f935"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.9.3/STDOCX.xcframework.zip", checksum: "eb1b8ef11cf4c6adf9f1c7549f4f6897d923ebf1dd4ed3096bcb5cd7ff3b8a95"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.9.3/STExcel.xcframework.zip", checksum: "174afbb594853115af1c04e50040a4783dbabc7ea931ea90f187051fcc2e0d75"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.9.3/STTXT.xcframework.zip", checksum: "c88eb07980067e72b7ee08104874dfa58b1efbaed7ffbd1c0951cb5ca0e1f0a0"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.9.3/STPDF.xcframework.zip", checksum: "ed701f603aff0b5a7146df3ec61b08f4915b9d56135b3be8a174d310ee9d8da9"),
        .binaryTarget(name: "ZIPFoundation", url: "https://github.com/Palerosy/STKit/releases/download/0.9.3/ZIPFoundation.xcframework.zip", checksum: "41196ade2eec653584f3471cd06fb8ce0cb251b79355fcc3a37fc067827180ba"),
    ]
)
