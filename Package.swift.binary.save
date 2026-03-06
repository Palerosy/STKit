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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.39/STKit.xcframework.zip", checksum: "4fde8e69d83ef873499e70f6c25a9d479f9c50e6789dee388e20b1de86a671ee"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.39/STDOCX.xcframework.zip", checksum: "6c7ec4f8dc71b9a6832150051b9e68306489ba603d9fc89baef873ff61934cc6"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.39/STExcel.xcframework.zip", checksum: "c7a854e8a75c49c72379a07722bb551d7425517193e2d63069021c7717444808"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.39/STTXT.xcframework.zip", checksum: "15c02b8ae7992ed3bb808172354aca3c371671442b7dba2e04fdb89b3b8c3b5f"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.7.39/STPDF.xcframework.zip", checksum: "d3e5abc40839365624c7755d3ed3b526f34e14a5bbd8a8f108c70a862ed8a829"),
    ]
)
