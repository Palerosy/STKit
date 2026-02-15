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
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.2/STKit.xcframework.zip",
            checksum: "aa91208a4d165d9f845ffa9ba3b7afb27162d22a98a18634ea3b7541f4a3725b"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.2/STDOCX.xcframework.zip",
            checksum: "5197ef3fb21593e6f61f07c5dcdefcb8422c1d5912dd3657270a194ce468369e"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.2/STExcel.xcframework.zip",
            checksum: "3ad9356678591ed7532c8124a9482ccf3026cd9e9084db2c1b6983c70198c75c"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.2/STTXT.xcframework.zip",
            checksum: "14cdd5cf039af04710e2eb82987cd340ec4c92b3f00a678f4e4476bd18494d74"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.2/_ZIPFoundation.xcframework.zip",
            checksum: "fb194a6f8b58877e7509d3df81832b8174c52835b961be72e4b8c04f4340cfc9"
        ),
    ]
)
