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
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STKit.xcframework.zip",
            checksum: "20a9accb7b696e7830f1d0c71c3e09c5712662e8125fd78bbdea8c467894a040"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STDOCX.xcframework.zip",
            checksum: "980a5d4c7c271d2fd0940a3354d205914257d26b61bb1d49436ccaa4932264f1"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STExcel.xcframework.zip",
            checksum: "a63e858a539aec80e6800d94a9d8c4667117bc11eb49eb6f697c10e849ed3fda"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STTXT.xcframework.zip",
            checksum: "bc53fb5562ee30301de3159c55a5078c4469a93fb4f292da9e07f9cc32d6adc7"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/_ZIPFoundation.xcframework.zip",
            checksum: "20745d04fcc5b47f08091e43fcadb5c671b24a677e49aa0b7b725a3c0a8ea95b"
        ),
    ]
)
