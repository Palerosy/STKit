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
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.4/STKit.xcframework.zip",
            checksum: "96433da55dead1882f485639ffb6b3402fe260f8cc40cc3c05056a2f16fc5d90"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.4/STDOCX.xcframework.zip",
            checksum: "5687d80f6a3458afcaeafdc03cb83ea07f4d92187cafec427f52c51f9c96d6ae"
        ),
        .binaryTarget(
            name: "SwiftDocX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.4/SwiftDocX.xcframework.zip",
            checksum: "4931230db18ff15b252865ff4e7638a3e6028726fa18e0867d835c0cef484df0"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.4/STExcel.xcframework.zip",
            checksum: "35efa02852f58691b5951924e384a30dc646f3382aa25025d3936bb13dd7c421"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.4/STTXT.xcframework.zip",
            checksum: "9cce25572d33ffa592183ae1c522550624a5ef334a0180f09ab83be7a78914d3"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.1.4/_ZIPFoundation.xcframework.zip",
            checksum: "01bd58caa257258bcff3ddc040ee05e95b82a77f2a7e9688143c6d5c3f30db9a"
        ),
    ]
)
