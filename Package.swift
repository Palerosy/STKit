// swift-tools-version: 5.9
import PackageDescription

let version = "0.9.5"
let repo = "https://github.com/Palerosy/STKit/releases/download/\(version)"

let package = Package(
    name: "STKit",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "STKit", type: .static, targets: ["STKit"]),
        .library(name: "STDOCX", type: .static, targets: ["STDOCX", "STKit"]),
        .library(name: "STExcel", type: .static, targets: ["STExcel", "STKit"]),
        .library(name: "STTXT", type: .static, targets: ["STTXT", "STKit"]),
        .library(name: "STPDF", type: .static, targets: ["STPDF", "STKit"]),
    ],
    targets: [
        .binaryTarget(name: "STKit", url: "\(repo)/STKit.xcframework.zip",
                       checksum: "b0577a8806ac7110931f98c48e0e90906675219d384b6d6d0fb91f365f5d66fa"),
        .binaryTarget(name: "STDOCX", url: "\(repo)/STDOCX.xcframework.zip",
                       checksum: "a23a1fb292718e099fa905e9482ced8bedec2953efba86a4bd296c3f9be6555f"),
        .binaryTarget(name: "STExcel", url: "\(repo)/STExcel.xcframework.zip",
                       checksum: "b3c1cb4bf29e38d15baff5a1755f842c509e71e82c601eccba02b4e56a509e11"),
        .binaryTarget(name: "STTXT", url: "\(repo)/STTXT.xcframework.zip",
                       checksum: "6bb894a1ed76420912bd36d158f78934839c2f79b71fa904d4ee4a059994f8ce"),
        .binaryTarget(name: "STPDF", url: "\(repo)/STPDF.xcframework.zip",
                       checksum: "12d32bcc730bda4db0e085ae955c116c98afb594feb6fe72b670f5023a6d6823"),
    ]
)
