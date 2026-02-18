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
            url: "https://github.com/Palerosy/STKit/releases/download/0.5.0/STKit.xcframework.zip",
            checksum: "9f6864ce3f0a9bf3ca4d806c92356319d559c5e41fac66430e429f23deeff48b"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.5.0/STDOCX.xcframework.zip",
            checksum: "8dbe216b52ffe49ae730279801fb6bc5b173b564bcba80a7897740b1793977a8"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.5.0/STExcel.xcframework.zip",
            checksum: "bc002aaf120b8f9d175ad1f6e7328ad7584be2b4bead889b3bbea84c2c6df617"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.5.0/STTXT.xcframework.zip",
            checksum: "18a4139cab50a0dac1ba50d5d06958d8e286352c7577df35cedaef6a14477d90"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.5.0/_ZIPFoundation.xcframework.zip",
            checksum: "2f45af142cda014f0aabe8f2257cb0ac5b2d9aa0d1fd59e75e85ca8e8300fd1e"
        ),
    ]
)
