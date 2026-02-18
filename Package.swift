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
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.10/STKit.xcframework.zip",
            checksum: "d3681d30c9e2b07433e46763be7552099f594a611d79474b17780281aabe353f"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.10/STDOCX.xcframework.zip",
            checksum: "2a8ef5c840d244de98002acfc667cd95e00869c484c7d3cb9ca6dc3acb279f33"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.10/STExcel.xcframework.zip",
            checksum: "8e7b4b3198fae1b4487046784f426c49a18b4aebe5370871ad6c3402b5f45330"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.10/STTXT.xcframework.zip",
            checksum: "127150c5daad88de57f983d9360add3ab4d34029f9e09ff14ed8f2265a66884c"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.10/_ZIPFoundation.xcframework.zip",
            checksum: "dd425c1b6abf1c9ba015b3033ca05aa5af53651811e10eb81833f9e0cccfa387"
        ),
    ]
)
