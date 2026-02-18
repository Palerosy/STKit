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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.23/STKit.xcframework.zip", checksum: "b83e7d94bc7b7b504b8dc1e4f164ed3f788f7664883225c7c1ecc736a1b78517"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.23/STDOCX.xcframework.zip", checksum: "f8d92c825eae9f80ba710dc495736811f96ebbf77657d2f2db796b2ff455677a"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.23/STExcel.xcframework.zip", checksum: "9e3dbd82ae72f4b6cd67debe4da122d92265449ee51462036aa105397b868626"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.23/STTXT.xcframework.zip", checksum: "c72a9b3edb800e17418dc8be99d6d98702362f513bb3d712d9d1217e3e97f8fb"),
    ]
)
