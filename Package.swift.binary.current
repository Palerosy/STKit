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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.33/STKit.xcframework.zip", checksum: "5a8182efafbe07fa5b0d79b4bd6659a7c488efb5daf9d83af0f714a28bc0c0bb"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.33/STDOCX.xcframework.zip", checksum: "c4c7ca23683d0e9028042bc267e5ec97872052e1f522c000b2ba3db5bc6759f8"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.33/STExcel.xcframework.zip", checksum: "7cd1e28e9d7c6342507bbf5e681671703eaeb5749a943ad0d26fe988db1c612b"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.33/STTXT.xcframework.zip", checksum: "b4c934eb69141e83dd6f07dcefb135dbb1041b72da0813e2148fff9f82fb8393"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.7.33/STPDF.xcframework.zip", checksum: "11052c17d52686156c90726826f49216ec5a3d5c012a4350515ba87a5cee7546"),
    ]
)
