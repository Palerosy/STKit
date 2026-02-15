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
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.1/STKit.xcframework.zip",
            checksum: "fb59f510fafef47f3d864b6b088fc13f51a310697e611ec8d81c6942e429ba96"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.1/STDOCX.xcframework.zip",
            checksum: "a68953502184cc8fb3be1846e72af977a832780949bed51412553c61e4063689"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.1/STExcel.xcframework.zip",
            checksum: "4b60594a0da4b5f07497f6d9c6256c46aa4008ccbd27b2acacc28a2f80168992"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.1/STTXT.xcframework.zip",
            checksum: "b637c541dbc7b77877b63344578f1e19b315838bcd5ae118f44d094d589f1190"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.2.1/_ZIPFoundation.xcframework.zip",
            checksum: "49a96c7d9d46256a200794918dc45b6067de8bdd2de5c56f85f5793a4262b193"
        ),
    ]
)
