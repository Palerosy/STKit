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
            checksum: "ab3172e7055bd9dd4f7267f90965939f752ef734c339d51a0ffda9a0863906cd"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STDOCX.xcframework.zip",
            checksum: "f26e8bf02d8c0f149acedb49b5097faa60510ed10c5f4c25ee70402d4d5c3d20"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STExcel.xcframework.zip",
            checksum: "81560603d219e4a4c911a1b01daf4084a33044c9233970d95add05a9a2878ba2"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STTXT.xcframework.zip",
            checksum: "3edc8e7884915bfdcdc1569698f72b05c298fe7ed69ee1f7b808f1100b460d7f"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/_ZIPFoundation.xcframework.zip",
            checksum: "8b770ffdd6886a4739a2fdb2e09f96be09bb6a9d72fe9436f20681e8f735b0c2"
        ),
    ]
)
