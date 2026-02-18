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
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.1/STKit.xcframework.zip",
            checksum: "8755985c209830456d8818e1dd97aca5166edccf1551928c9f7a6d7274258488"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.1/STDOCX.xcframework.zip",
            checksum: "af6f6298b635def5791b7257480d499986371876de1c463be625ea0a83243c07"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.1/STExcel.xcframework.zip",
            checksum: "532281e5752c5e40413101a54aac5df7ec23ab92bd2a39635a54e560a68261b4"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.1/STTXT.xcframework.zip",
            checksum: "dea8509037b01e5cda7d67b5589420643b78f540229df1cab5602ea89714bf95"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.1/_ZIPFoundation.xcframework.zip",
            checksum: "83d4990ae1327dd66a448fc1d1584095fa214be6fec9c7bb3727ef53321a17de"
        ),
    ]
)
