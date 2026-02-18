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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.21/STKit.xcframework.zip", checksum: "77255d8a50be1887574923e981d4bf8364432122acc641221a937152ac2dddc2"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.21/STDOCX.xcframework.zip", checksum: "405aa27ee8cdad269def6a9c89c1eff470ecd96305df01985fa7193bb360e5cd"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.21/STExcel.xcframework.zip", checksum: "24817715c546b6a44a07cb1715b2b1e518af085c79eaa6967d4e8a2c421e3d80"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.21/STTXT.xcframework.zip", checksum: "fb4210277edd97a77a6d7d7fd0bc7c4fba899606ce300a37b13728c03173d949"),
    ]
)
