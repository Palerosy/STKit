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
            checksum: "8c0e0c837b174212b1c08c646af7b0c5a28cc809fca9146ad4afa1015e1f3ed4"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STDOCX.xcframework.zip",
            checksum: "4dd58761f4e09e0384b1110c12c0abf23ebb0199bcc38b5455383dbca1b5218e"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STExcel.xcframework.zip",
            checksum: "deb52a469acca66c9b785b2487e35c367fc2ee50d4be2ede5376a951ee527dc8"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.0/STTXT.xcframework.zip",
            checksum: "e802224bbf894af06d4821ea2b3beccedbc62d9d6c8273aca88b6add074275e4"
        ),
    ]
)
