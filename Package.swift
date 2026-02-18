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
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.13/STKit.xcframework.zip",
            checksum: "2071df50a8787134160f64a5516298c5417a2c2ee0645d865daeb940f942f3d9"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.13/STDOCX.xcframework.zip",
            checksum: "31556abd676e128626dbd3e391a8282d751c9489f948a0ea76843e4c55d83987"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.13/STExcel.xcframework.zip",
            checksum: "61c34d997f4833ce059bb1854af8e781a8b78fa3e3a8c33bef059350f44588f7"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.13/STTXT.xcframework.zip",
            checksum: "636f3156aadbaead7196f5fb6b146f49ef4baed9e1fa64b182b2537425ddfbab"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.13/_ZIPFoundation.xcframework.zip",
            checksum: "bb044e8d1014869b804a4604594c4b317e6a296c0bb45635fcd32f8494fc56c8"
        ),
    ]
)
