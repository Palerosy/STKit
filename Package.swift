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
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.9/STKit.xcframework.zip",
            checksum: "3f0481234474e7a314501d30a4f5c88660a1a8eb4e15d07264d1cd86b053e752"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.9/STDOCX.xcframework.zip",
            checksum: "24272956339eefd18ed13f9a9aca94efb552d5ad6db2db866b176f0399d0dc9e"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.9/STExcel.xcframework.zip",
            checksum: "2e79513325008d3fb8bb4fea647053fae7502b4ec367cc705c8b6bcf40e2ff33"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.9/STTXT.xcframework.zip",
            checksum: "67f2ca1c25b9792deffb20ab92701e521f5e2d19547640930ad9dc39bbc6f3fb"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.9/_ZIPFoundation.xcframework.zip",
            checksum: "50e79513c28120d134a4f486f76492164276e3ac5c593836688aae7d61a3b2ee"
        ),
    ]
)
