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
        .library(name: "STPDF", targets: ["STPDF", "STKit"]),
    ],
    targets: [
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.40/STKit.xcframework.zip", checksum: "67847ab4e5e9057a3b9ebc8eb92912f5268feb79a6b13a3cb1a1e9ffa115a63c"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.40/STDOCX.xcframework.zip", checksum: "7c10ad7cfe362a483ed16b074f406ddcb3570c473cf3506dcc3db79550992e2c"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.40/STExcel.xcframework.zip", checksum: "50c49ed6faee560a32249771fcbf5dbad79467cc2f3df9cfcdd85035da0449a0"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.40/STTXT.xcframework.zip", checksum: "4a4dd140e947858da46069f0723ebe59d9e0cf5a2fe5e448c40ea62960cf2618"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.7.40/STPDF.xcframework.zip", checksum: "eff432e5c16c8e9e7b54162c64c2733e82d7350fc23ccd3ef552c2d7abc23a6d"),
    ]
)
