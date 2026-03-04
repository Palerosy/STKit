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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.42/STKit.xcframework.zip", checksum: "b2d4bd7a1a9d2437fa0aef23614e5a33825d422af409943c549ac7fc948f64e0"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.42/STDOCX.xcframework.zip", checksum: "04f66e37cd216c21d1e862938d9eeb50a623e84ddaf9f969a86d423196982de8"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.42/STExcel.xcframework.zip", checksum: "272dac4358fbaa21b05253135090026fa936e6573e529f5a830b819801b02333"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.42/STTXT.xcframework.zip", checksum: "2034250a97901bcaeee70b7fd01d392a6f888dcf52a45613fbf23339ee66df89"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.7.42/STPDF.xcframework.zip", checksum: "082b401d39ab5784b27970cb3e6318ac2aff806790f3f44f5445aee6432aa4c4"),
    ]
)
