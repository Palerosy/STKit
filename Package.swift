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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.19/STKit.xcframework.zip", checksum: "de4bc9512d65ca98f97b9409dddc24ef14dfbbf5cd62710b6bb4827cd1dd4374"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.19/STDOCX.xcframework.zip", checksum: "de56d7b426458f8af65040af7737bed0817fc20273bc53437990936c370682ec"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.19/STExcel.xcframework.zip", checksum: "0c9c93bd2c0254af4a320802a5916770bbde03d56bd3d084dbbe1e24ef2d902d"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.19/STTXT.xcframework.zip", checksum: "24157bb12dd0be8fd08dafbe70c0a1ae78dbe9cf2aa13074e2d84e96a2ab55bc"),
    ]
)
