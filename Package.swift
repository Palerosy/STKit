// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "STKit",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "STKit", targets: ["STKit"]),
        .library(name: "STDOCX", targets: ["STDOCX", "STKit"]),
        .library(name: "STExcel", targets: ["STExcel", "STKit", "ZIPFoundation"]),
        .library(name: "STTXT", targets: ["STTXT", "STKit"]),
        .library(name: "STPDF", targets: ["STPDF", "STKit"]),
    ],
    targets: [
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.9.1/STKit.xcframework.zip", checksum: "14adbf332c370bdcf967d241987d054410b3a42d3858b6d48c521b4c0f72905e"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.9.1/STDOCX.xcframework.zip", checksum: "4e83ea1dd1b800de768f48fa853c3f65c827d5dece0f67828217981479927da1"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.9.1/STExcel.xcframework.zip", checksum: "c9978ed59d3e6d217157f8cfe13862dae63779b76365b947b8ca7351c015cbfb"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.9.1/STTXT.xcframework.zip", checksum: "0b2ccc13f3e86fae06b63054828a4aca7a4eef877e32ad5026471b757b55e37a"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.9.1/STPDF.xcframework.zip", checksum: "a5aaa3be84222328e98d9161cb22c9820390565dbe710689ac1463d5dbd97865"),
        .binaryTarget(name: "ZIPFoundation", url: "https://github.com/Palerosy/STKit/releases/download/0.9.1/ZIPFoundation.xcframework.zip", checksum: "41196ade2eec653584f3471cd06fb8ce0cb251b79355fcc3a37fc067827180ba"),
    ]
)
