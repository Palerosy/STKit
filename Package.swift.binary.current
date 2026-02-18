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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.17/STKit.xcframework.zip", checksum: "4f117960702efa4709ded43a0e1fa78751d05787002ecbff72afed68f8178f40"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.17/STDOCX.xcframework.zip", checksum: "2551ba824478e22faf57def92241a33436af16750820cf78f0680a8fae383c3e"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.17/STExcel.xcframework.zip", checksum: "c079036b21297f773b4f0dda8c97e6b5f1eb5a04bb19a5dbefd3f23f34f58c72"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.17/STTXT.xcframework.zip", checksum: "1066fff0530d4b57cfc138afb25601defb6248683c25c88902a30d7f2e957a35"),
    ]
)
