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
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.6/STKit.xcframework.zip",
            checksum: "28392d1f19232e8490c2ed937bcccd2db601ff2d0f1c7056d928ad878d4b3ad7"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.6/STDOCX.xcframework.zip",
            checksum: "8793c64f2a2dcdc17272eb34aed31ebd7cc5ce4823a35e05790d4334ba22b5bd"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.6/STExcel.xcframework.zip",
            checksum: "37c4dd2ef989026523f12eb3ec17607cc7fe9b7d43709ced5e722b219c1639fe"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.6/STTXT.xcframework.zip",
            checksum: "4b6d52a3d1df914b70b414c0e88f6f2c23156fa8084f5551bae992202e75a97c"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.6/_ZIPFoundation.xcframework.zip",
            checksum: "044d29d81fb10bab3ba8d1154e10ac59e0abb000b6b08eaaaf95961035d0fae7"
        ),
    ]
)
