// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "STKit",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "STKit", targets: ["STKit"]),
        .library(name: "STDOCX", targets: ["STDOCX", "STKit"]),
        .library(name: "STExcel", targets: ["STExcel", "STKit", "ZIPFoundation"]),
        .library(name: "STTXT", targets: ["STTXT", "STKit"]),
        .library(name: "STPDF", targets: ["STPDF", "STKit"]),
    ],
    targets: [
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.9.0/STKit.xcframework.zip", checksum: "13fc3a116245b0a7ea7e76dd85b5b8fc3b3cfc2f7698031060b47cebd3c7471e"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.9.0/STDOCX.xcframework.zip", checksum: "63e3f8fe5854007003b71ded7be9203e8bafe5c89a0d40a0fdaf32a1d7bda9cd"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.9.0/STExcel.xcframework.zip", checksum: "cda8e4a48a2307461fdac1676ae65f7f41904ccc9c6cc7148b35becd114c084f"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.9.0/STTXT.xcframework.zip", checksum: "f9bf9455e429c867b3310651bc080a08c112dc99cc7f4ee0bc21b264ee3232e5"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.9.0/STPDF.xcframework.zip", checksum: "dc759d4c24d72743215789169600d408c3d256c34c4b65120fa884a42d19fa15"),
        .binaryTarget(name: "ZIPFoundation", url: "https://github.com/Palerosy/STKit/releases/download/0.9.0/ZIPFoundation.xcframework.zip", checksum: "41196ade2eec653584f3471cd06fb8ce0cb251b79355fcc3a37fc067827180ba"),
    ]
)
