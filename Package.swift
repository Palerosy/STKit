// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "STKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "STKit", targets: ["STKit"]),
        .library(name: "STDOCX", targets: ["STDOCX", "SwiftDocX", "STKit", "_ZIPFoundation"]),
        .library(name: "STExcel", targets: ["STExcel", "STKit", "_ZIPFoundation"]),
        .library(name: "STTXT", targets: ["STTXT", "STKit"]),
    ],
    targets: [
        .binaryTarget(
            name: "STKit",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.3/STKit.xcframework.zip",
            checksum: "e160e0bd97a11c80e884c777903e4b34c6d294661abc0e871a895b2cb8d81b5e"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.3/STDOCX.xcframework.zip",
            checksum: "e14759edd840a3a8da6d965a99a3ce00e87572945224acab648f0d4488748e67"
        ),
        .binaryTarget(
            name: "SwiftDocX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.3/SwiftDocX.xcframework.zip",
            checksum: "a5e04f785147bb6034e3e5d64dc27fba8e344168fe9e3a5dda4c506d78e3a189"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.3/STExcel.xcframework.zip",
            checksum: "2a4225ac3f3444f9996bc3e3ac6e8f0d1bf3646c1cbc916c8336acb0a0735009"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.3/STTXT.xcframework.zip",
            checksum: "2c593416503583baab069002e55a51ecfbfd48d3ef0b2e172d8de8e576b4ddf8"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.3/_ZIPFoundation.xcframework.zip",
            checksum: "e0b42239eff6081b9ee24fa2e2264e66481033daa5d636be037b3a2b58be6596"
        ),
    ]
)
