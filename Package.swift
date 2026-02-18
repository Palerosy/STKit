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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.30/STKit.xcframework.zip", checksum: "81e5e241d94c9ae044bf86553bdaba09c98fdcdbf9ef07e3c79efdf85b9b05d0"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.30/STDOCX.xcframework.zip", checksum: "d399738996685b964ba048b2550a2d5da2f6322fe67f70b54e04a14f52bb3a3c"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.30/STExcel.xcframework.zip", checksum: "909a98cbf86a570707e3fa8acc93e8e391bce3b1fbb26fe10deea06c1303533d"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.30/STTXT.xcframework.zip", checksum: "759e692fcde17797c5f02d2729b106b85e6762541781be058099e06d609ebd55"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.7.30/STPDF.xcframework.zip", checksum: "b785cc80ca52d15ef06d9d4279b9a6d5a107434acd8b985112c7838e53e07f5e"),
    ]
)
