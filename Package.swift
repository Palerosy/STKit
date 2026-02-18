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
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.0/STKit.xcframework.zip",
            checksum: "41cc31afc35c56b646ce82861e2861841c3b2a475840d82f4d9242fb9d38b102"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.0/STDOCX.xcframework.zip",
            checksum: "286ca8c686cdf1323eabac0ac8083706ef79eea371583080970c3abc39d3db4d"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.0/STExcel.xcframework.zip",
            checksum: "352ce65335b2e63a3a77a176fb710e14f788c5237b957dc1e0958508e8d8b30d"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.0/STTXT.xcframework.zip",
            checksum: "27aab7942a75b0e24c6a0dff37aadace9ddb7164afc78c6e1d0f40872aacd46d"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.0/_ZIPFoundation.xcframework.zip",
            checksum: "eaa50e89d5b0b9c9104f3d10442d100e22b940d7571c7fb485df45f2c1369859"
        ),
    ]
)
