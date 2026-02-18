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
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.12/STKit.xcframework.zip",
            checksum: "520775143821a02daa1daef7cc18448ecf0a280630bc80633aa150ce1034ca2d"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.12/STDOCX.xcframework.zip",
            checksum: "6a7fc461b90a35d9bc1dd8d6bbd65f524bce2b1cd197dbc984e4b67a875bf1f7"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.12/STExcel.xcframework.zip",
            checksum: "8f0b5a8592774e2f7a5f8825a6faac4fd174afa6b78472e28456480cde8ff659"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.12/STTXT.xcframework.zip",
            checksum: "fc3f6a1b978bd9246f7d935ac0868b3b22aae4ec591fdd6809014716e6a9caf7"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.12/_ZIPFoundation.xcframework.zip",
            checksum: "064f73c8bd92a834052f505b3919003c6b63401ce2e48bb531cdcafd0a6dcd51"
        ),
    ]
)
