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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.26/STKit.xcframework.zip", checksum: "f0da78f70d75b3bbebb0179007f0285e6c20e32481ed2dfa1d40250487dc0080"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.26/STDOCX.xcframework.zip", checksum: "3da633266aade16bd7fc69a51044767f8a6eb44555b6ff660960782d1844d5a1"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.26/STExcel.xcframework.zip", checksum: "615e5a1866414cb9b34499727ffd63e72ccca01407cd9e052e69d976666c52df"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.26/STTXT.xcframework.zip", checksum: "91cc461bb78d9d88f762451133a16d1f27e1d68b93d0d04f16d118988f574c17"),
    ]
)
