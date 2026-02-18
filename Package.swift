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
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.7/STKit.xcframework.zip",
            checksum: "a4c6ba2b97cefcb580c56edc9b62d1d8b06afdf3b4f0d26a62661e35d13e6516"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.7/STDOCX.xcframework.zip",
            checksum: "bbbdaf1d86c2ab444382b62d23c2ccb8e32cc272026400bdf6fdcdd97fe564e8"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.7/STExcel.xcframework.zip",
            checksum: "fdf72b2d9e6fc49acd4c125bd3a0c6b6c332b829f2b522eaec9893a8f2ad52a2"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.7/STTXT.xcframework.zip",
            checksum: "1f3045f69550e2425578fb8278734cc3bb94750886682b927394ff18ce72cf84"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.7/_ZIPFoundation.xcframework.zip",
            checksum: "23e5f884cc214c4c2af812b095c3fc4306783495769aaaff33d0b1c793cb4a6e"
        ),
    ]
)
