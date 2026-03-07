// swift-tools-version: 5.9
import PackageDescription

let version = "0.9.6"
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
                       checksum: "a04ebe0b3931b9941feaefcae848d23561a747b42542321b8873fbb6e10caaea"),
        .binaryTarget(name: "STDOCX", url: "\(repo)/STDOCX.xcframework.zip",
                       checksum: "31a3b617685c8ed1a3508efc74f5c4026061fc6ef47308ad6f9bdc534a9f9012"),
        .binaryTarget(name: "STExcel", url: "\(repo)/STExcel.xcframework.zip",
                       checksum: "da58a35be418da18799b01b326f315a7c3252d82cd29d80933cc987740587862"),
        .binaryTarget(name: "STTXT", url: "\(repo)/STTXT.xcframework.zip",
                       checksum: "c1daaddbd52d0d8d19378b0511533cc0c9abaf4f77de369594ac08f2a53169a0"),
        .binaryTarget(name: "STPDF", url: "\(repo)/STPDF.xcframework.zip",
                       checksum: "9b0b079c4e226e7bd4f0460c20310da7d8fd0382e6b003ef9542a8e0a046fd8e"),
    ]
)
