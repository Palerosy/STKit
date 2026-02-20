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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.34/STKit.xcframework.zip", checksum: "650b773b6879c02af21fb82d285654da999a644925d48e2e900d2e5db9dda968"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.34/STDOCX.xcframework.zip", checksum: "1240d54576107f259f62e95af46e02fc0bd8150b23137fd65c9b9cb692269ac2"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.34/STExcel.xcframework.zip", checksum: "efcefae5768f9006504eb184e260d6896069234c6ef0593bf31b13981dce5fc2"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.34/STTXT.xcframework.zip", checksum: "2cd92291931dbd22f556aba9cdb2a4cf635d6d1599ea017dc1ad2506e297fccd"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.7.34/STPDF.xcframework.zip", checksum: "e27c2e3aaa115e6869bd2893def90ba3491a30790d014a8139ea96f74785abdc"),
    ]
)
