// swift-tools-version: 5.9
import PackageDescription

let version = "0.9.7"
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
                       checksum: "414594ee0178a7a92e20259467b8d83266ab5626fbc7d9f82eed7791c81d3904"),
        .binaryTarget(name: "STDOCX", url: "\(repo)/STDOCX.xcframework.zip",
                       checksum: "e38d92b75af847b6a8b126bc0b7698c526b3f442155d3d0b442a09833c7e5221"),
        .binaryTarget(name: "STExcel", url: "\(repo)/STExcel.xcframework.zip",
                       checksum: "007b037526c7faf02628c91929496d75f52f08ac1cc510bf2c6b72c1ed3f0a12"),
        .binaryTarget(name: "STTXT", url: "\(repo)/STTXT.xcframework.zip",
                       checksum: "8bd66caacf15afa880ed413a5de5424dc1a58c2cfa91c378e75b73120ca1072b"),
        .binaryTarget(name: "STPDF", url: "\(repo)/STPDF.xcframework.zip",
                       checksum: "e980541617c6a78a9f64291da98fa8d9878e6d14c9d8235b52ef72526e1564dd"),
    ]
)
