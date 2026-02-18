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
    ],
    targets: [
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.18/STKit.xcframework.zip", checksum: "cd434819cbf8d0ceaa96b5943518ec2c689fc847cdcf58912ebc404e09a273ff"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.18/STDOCX.xcframework.zip", checksum: "17ef3ac1e09bab9df25f6756725ffa22c695b44126279c081507f12582d4dbaa"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.18/STExcel.xcframework.zip", checksum: "14f9421ad31d361c1706ea159572a8e1b3ca547bc75352964e7bf4a1b6f587a2"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.18/STTXT.xcframework.zip", checksum: "1d75333c59e622178ce95d67b714896c2b3245e03fc9a7feaebf08f84e6105d1"),
    ]
)
