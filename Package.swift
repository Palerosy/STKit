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
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.2/STKit.xcframework.zip",
            checksum: "1d6350a81ebace50cca03ead18f3d75e345423234cf929624b5c08890f87d92a"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.2/STDOCX.xcframework.zip",
            checksum: "ac80d04877173d93d4d49ac0f0f891ef9cb0a6b68fac681fcde5dac27bf65583"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.2/STExcel.xcframework.zip",
            checksum: "99ca6a7b170ccce71abf447c05eb380a0197b09eb8b46d3b429fb742d6ee2a87"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.2/STTXT.xcframework.zip",
            checksum: "456c8306acc4875a6af0996d4e125e511f7167e57bfaa35444278a76c812138f"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.2/_ZIPFoundation.xcframework.zip",
            checksum: "c85b38275103a920978f9d3d1620f5ffe3559a497754296b18c3858d61e8a534"
        ),
    ]
)
