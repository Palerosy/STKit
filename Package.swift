// swift-tools-version: 5.9
import PackageDescription

let version = "0.10.1"
let repo = "https://github.com/Palerosy/STKit/releases/download/\(version)"

let package = Package(
    name: "STKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "STKit", targets: ["STKit", "STKitResources"]),
        .library(name: "STDOCX", targets: ["STDOCX", "STKit", "STKitResources"]),
        .library(name: "STExcel", targets: ["STExcel", "STKit", "STKitResources"]),
        .library(name: "STTXT", targets: ["STTXT", "STKit", "STKitResources"]),
        .library(name: "STPDF", targets: ["STPDF", "STKit", "STKitResources"]),
    ],
    targets: [
        .binaryTarget(name: "STKit", url: "\(repo)/STKit.xcframework.zip",
                       checksum: "7232a71c43652321008a54048042e0f3855cb0c4d8cc341917c93db1101377a8"),
        .binaryTarget(name: "STDOCX", url: "\(repo)/STDOCX.xcframework.zip",
                       checksum: "271eb7d8e4c566209cff8799404b346a75d32b9112bb6f87adac7d4d4f071fe7"),
        .binaryTarget(name: "STExcel", url: "\(repo)/STExcel.xcframework.zip",
                       checksum: "11182184642b2bc6bddb0f9844a8db4d4011e1648b2bfd13de2c36b3b4ea52e5"),
        .binaryTarget(name: "STTXT", url: "\(repo)/STTXT.xcframework.zip",
                       checksum: "5c2fc8ea00aa9e5a3d821b57363728c081af46762d9493004837d8f47e3b0f09"),
        .binaryTarget(name: "STPDF", url: "\(repo)/STPDF.xcframework.zip",
                       checksum: "b087f28726ec0d4504b440991333fb756e54a0555ca3e40d80e1cf688cbcf0be"),
        .target(name: "STKitResources", dependencies: [], path: "STKitResources", resources: [
            .copy("STKit_STKit.bundle"),
            .copy("STKit_STPDF.bundle"),
            .copy("STKit_STDOCX.bundle"),
            .copy("STKit_STExcel.bundle"),
            .copy("STKit_STTXT.bundle"),
        ]),
    ]
)
