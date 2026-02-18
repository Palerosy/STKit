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
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.5/STKit.xcframework.zip",
            checksum: "4db4295f1d719fdf93d5328217f0d3171dad3c931bd992ef519f92a8da5b3156"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.5/STDOCX.xcframework.zip",
            checksum: "9746f1d6b58ea0c1b2b17ea59db7f0835cb18a9140c3a8129c26413f0b9efea3"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.5/STExcel.xcframework.zip",
            checksum: "8668b75f8a27259dba2109e4ac2e3cf9c660cef048ae6142967d621b61834017"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.5/STTXT.xcframework.zip",
            checksum: "65e2815fd8d765384490cea302ab60a6da494e8d278448ec028039f8b93e2025"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.5/_ZIPFoundation.xcframework.zip",
            checksum: "606977f4b5b766db027564be6ff561746509b6f5f723aee967ecf6f77dfaade6"
        ),
    ]
)
