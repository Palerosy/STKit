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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.9.2/STKit.xcframework.zip", checksum: "74546f13ec03c725f4ce846bbbb795a49e5eff4bee2e4f8aba18cc3bad9d3713"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.9.2/STDOCX.xcframework.zip", checksum: "9abc062ed544ce0b8108e2b60fe78d5b2a7392ee94e367fc5843bd141ce4d677"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.9.2/STExcel.xcframework.zip", checksum: "88b5598e4bd1638f489b716b949aef91130c4812743cf788261f38695a2d9050"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.9.2/STTXT.xcframework.zip", checksum: "85b248763e46a4a9d0267e90cb82bf0ddf0146c512c66289c82f5677a0b9612f"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.9.2/STPDF.xcframework.zip", checksum: "1ad78f9ff2a1a10f57b521d2154cb4b624386c4b1d3e3b0e95f45a0f858f3c50"),
        .binaryTarget(name: "ZIPFoundation", url: "https://github.com/Palerosy/STKit/releases/download/0.9.2/ZIPFoundation.xcframework.zip", checksum: "41196ade2eec653584f3471cd06fb8ce0cb251b79355fcc3a37fc067827180ba"),
    ]
)
