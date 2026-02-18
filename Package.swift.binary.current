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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.27/STKit.xcframework.zip", checksum: "305668a1c410ebaa14ac645049326f193913b61a5fdea9b5579865ebd99db2ea"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.27/STDOCX.xcframework.zip", checksum: "764169bca84c816cd4f43a3d9c147bbeb3d900fbb38f7b604a967c74414188cf"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.27/STExcel.xcframework.zip", checksum: "8c1bf72e3f76019d2737c246059fb6465c540db01aec3bd99459e2dc968cc353"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.27/STTXT.xcframework.zip", checksum: "aa99c1e99a87e67917000996c6c6d87028782de8766a584ba0beed666a25a0c2"),
    ]
)
