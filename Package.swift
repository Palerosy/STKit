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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.8.5/STKit.xcframework.zip", checksum: "811ba249993904c3f87e82d2e32d12c2b2bd6eb0d5782573855e1e9900cb631a"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.8.5/STDOCX.xcframework.zip", checksum: "4dc33e12d366b35970bc7d63e8e8a17ec8fdf32c832aa3f2026bf23f9c3082a1"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.8.5/STExcel.xcframework.zip", checksum: "4197ecc359af8d061808b152220693c3472addcbe6400dbeb3b387c19288ac24"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.8.5/STTXT.xcframework.zip", checksum: "0ccc1b0f81230f2d32440f6abb4ac27fd68f021de690f16692582fff5e95eb13"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.8.5/STPDF.xcframework.zip", checksum: "6ec26b192287cc17dc9a4660eb8fcaae27775e6c7b45c3e138c14217d4d57501"),
        .binaryTarget(name: "ZIPFoundation", url: "https://github.com/Palerosy/STKit/releases/download/0.8.5/ZIPFoundation.xcframework.zip", checksum: "41196ade2eec653584f3471cd06fb8ce0cb251b79355fcc3a37fc067827180ba"),
    ]
)
