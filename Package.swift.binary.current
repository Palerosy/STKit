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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.29/STKit.xcframework.zip", checksum: "b73a90d9b588fe47ea8c34edb95908afb317655e5fc55d5354f468674082e295"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.29/STDOCX.xcframework.zip", checksum: "1180a3f052bdc7a4319dc22296734212176ced907c2bc35a9161f5bf8ce47087"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.29/STExcel.xcframework.zip", checksum: "fe5feb4175aac656bb2d9244b8cca4dde573a482012339919d92304d129d05ae"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.29/STTXT.xcframework.zip", checksum: "98790ef3a496ae2a3fbd19b651996bd124b2e5686011459f70a196893f9d4108"),
    ]
)
