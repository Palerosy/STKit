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
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.0/STKit.xcframework.zip",
            checksum: "9f6c5aa72fea22658e5b73d7e916203c2dd8a07b152d86e3cb63e1945b0480b0"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.0/STDOCX.xcframework.zip",
            checksum: "61f27a584ee724227a368b732d8ff415583a4c29f583e01a32655717f45aec60"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.0/STExcel.xcframework.zip",
            checksum: "ece0da8298397d08a1cfc4648945bdd4ede2f181813765a865a4e88d4a47df85"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.0/STTXT.xcframework.zip",
            checksum: "84935d5b6bdb52be64f23195b76a95d92e3fa8c1ca383c321ad0421bea62ae9b"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.0/_ZIPFoundation.xcframework.zip",
            checksum: "9bf2457d558d25701926d986d736e4c59f92b4f6da232721ed9f27cc9359a764"
        ),
    ]
)
