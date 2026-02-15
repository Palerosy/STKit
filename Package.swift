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
        .binaryTarget(
            name: "STKit",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STKit.xcframework.zip",
            checksum: "2dfe54be6082f85a6a82f11933a80a3f61dbf01a5e1ac60fb33d543de664547d"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STDOCX.xcframework.zip",
            checksum: "c9f908b43fa3aabf46d48a13cd6ff9622802d878cbdaebbacaf6f6288581e919"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STExcel.xcframework.zip",
            checksum: "fda68cf86a49d04f3db4a5aebe57ebfe0f6481415091b53a1089deae729d1601"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STTXT.xcframework.zip",
            checksum: "f30c7e877a1d1c603376b514b0157feb2651bae1695a05a1f9fdbd189c6385a0"
        ),
    ]
)
