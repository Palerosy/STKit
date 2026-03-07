// swift-tools-version: 5.9
import PackageDescription

let version = "0.9.9"
let repo = "https://github.com/Palerosy/STKit/releases/download/\(version)"

let package = Package(
    name: "STKit",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "STKit", targets: ["STKit"]),
        .library(name: "STDOCX", targets: ["STDOCX", "STKit"]),
        .library(name: "STExcel", targets: ["STExcel", "STKit"]),
        .library(name: "STTXT", targets: ["STTXT", "STKit"]),
        .library(name: "STPDF", targets: ["STPDF", "STKit"]),
    ],
    targets: [
        .binaryTarget(name: "STKit", url: "\(repo)/STKit.xcframework.zip",
                       checksum: "d5a1f490d2d58e52d7baf52ff5c30dd369d5b204e586a7224847c786476b163a"),
        .binaryTarget(name: "STDOCX", url: "\(repo)/STDOCX.xcframework.zip",
                       checksum: "195010ee150bc3fd683de47a3cbcd786cdced117359e97141dc24dd78c0509b0"),
        .binaryTarget(name: "STExcel", url: "\(repo)/STExcel.xcframework.zip",
                       checksum: "c95153ea17b05505422409e9c1e6fcf9697c168fce3c205233dc95ba07a8f3ed"),
        .binaryTarget(name: "STTXT", url: "\(repo)/STTXT.xcframework.zip",
                       checksum: "962c9c098ddade8bacef408407810ab7b49ad3f203bb498c051f40dd45e6dec9"),
        .binaryTarget(name: "STPDF", url: "\(repo)/STPDF.xcframework.zip",
                       checksum: "2926e580e256f4fb3ff34bf504829b5aed641c275542e839e5b89b0d6b6dd8ba"),
    ]
)
