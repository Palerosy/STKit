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
            url: "https://github.com/Palerosy/STKit/releases/download/0.6.0/STKit.xcframework.zip",
            checksum: "aec7dc71f3d623c23dc2a751784fd77d00b79051c7a8b4d093d162aa740a47fb"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.6.0/STDOCX.xcframework.zip",
            checksum: "722248c1b278a8d77ccba2c1f09c0e404854bb8875365ab2f332c7c68a538748"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.6.0/STExcel.xcframework.zip",
            checksum: "aa0826937ec5714a5e600cb4f93fe36d1a977d6e95a4940b41e65b3ae66fd4fd"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.6.0/STTXT.xcframework.zip",
            checksum: "2d3763a5d64f5184cb2b6d2b07771f94a37b12be8eeff1729f2a948a43ff28fe"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.6.0/_ZIPFoundation.xcframework.zip",
            checksum: "b4bd9118e88a2b294ae370f23085763bd17cb9891796b81571452989956ab79b"
        ),
    ]
)
