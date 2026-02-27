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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.38/STKit.xcframework.zip", checksum: "e3feb0958a39bb4d3ef6e8164181195e38a3c16dac1a764f820e37fb7310c33c"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.38/STDOCX.xcframework.zip", checksum: "fc5084c65f4b28602b6d5c0cb31aad6efe4d77a5b033075a276b4dc1addd0888"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.38/STExcel.xcframework.zip", checksum: "2e5ecefbfc6a375389587ee75828dafa3315b883740fffa49fec6f4436049308"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.38/STTXT.xcframework.zip", checksum: "5ba42b19e40496d9f692d7e7a830054d21e15c35e75b0a208ceb68232f631900"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.7.38/STPDF.xcframework.zip", checksum: "6bbd23e8764672deb16ebd8221293de062a3e0062dbdef2a4aeaa9f8817cdfa7"),
    ]
)
