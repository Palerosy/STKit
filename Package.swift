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
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.7/STKit.xcframework.zip",
            checksum: "2a36ff0a33639d946a770e5e16d549cdefbfbaa8dbf196de9dba20313e860b65"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.7/STDOCX.xcframework.zip",
            checksum: "d0842b91be68af514f8abbba866f489d44b37ee71e180acf4999fae0da8d6534"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.7/STExcel.xcframework.zip",
            checksum: "c739178e1965683c5308c8fd633fbc7fe32bce878de8aa66e82c55610c4d7aad"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.7/STTXT.xcframework.zip",
            checksum: "4439db04f99c53e20d4c665189873cd32f5e58d601f3c351de228fbe9b75df72"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.7/_ZIPFoundation.xcframework.zip",
            checksum: "c34d19003897b109509aab99b378778964100a81327a4e9bba1637a14c2c3bf1"
        ),
    ]
)
