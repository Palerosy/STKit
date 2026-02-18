// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "STKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "STKit", targets: ["STKit"]),
        .library(name: "STDOCX", targets: ["STDOCX"]),
        .library(name: "STExcel", targets: ["STExcel"]),
        .library(name: "STTXT", targets: ["STTXT"]),
    ],
    targets: [
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.15/STKit.xcframework.zip", checksum: "8112c4f3f7f08463f66de92d6d14dae6e46e8d6ae4fcca2ec3e276d302181e05"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.15/STDOCX.xcframework.zip", checksum: "140df71f519ced99a2c20c0838b815cffcc3f7d2bce59b95147ea7e88715b1b6"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.15/STExcel.xcframework.zip", checksum: "2ff0a0e2bd4ddfa32fd57ea4743a7aaa2baeb721e451b63ed8b3cec7e93632c7"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.15/STTXT.xcframework.zip", checksum: "09b7bb7abfb7cc58bdf0948ed0f1d8cff1ab10408cc5865aa267d6d9a18b3872"),
        .binaryTarget(name: "_ZIPFoundation", url: "https://github.com/Palerosy/STKit/releases/download/0.7.15/_ZIPFoundation.xcframework.zip", checksum: "8358e761fa8ea577f1fe5ed67cac149957580a2d654a9200eb24a946b84773f5"),
    ]
)
