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
        .binaryTarget(name: "STKit", url: "https://github.com/Palerosy/STKit/releases/download/0.7.41/STKit.xcframework.zip", checksum: "82a0e79d454c854f8ebb2ef6d3619f21890295c6dc02fbe0ba6646fdc2415bcc"),
        .binaryTarget(name: "STDOCX", url: "https://github.com/Palerosy/STKit/releases/download/0.7.41/STDOCX.xcframework.zip", checksum: "ddbb56f8738af6aa04972cdfa3d8182d1fcb83b6b02429b5a19eb2379744f72d"),
        .binaryTarget(name: "STExcel", url: "https://github.com/Palerosy/STKit/releases/download/0.7.41/STExcel.xcframework.zip", checksum: "07a4bf228cd78d5b33ee67bc4ee64fafd63ccb464ac53bb656220fe27761dd68"),
        .binaryTarget(name: "STTXT", url: "https://github.com/Palerosy/STKit/releases/download/0.7.41/STTXT.xcframework.zip", checksum: "a4ae12866d90bbf25837960c563475a20ed1fc4622d1b39295cac8265c72050d"),
        .binaryTarget(name: "STPDF", url: "https://github.com/Palerosy/STKit/releases/download/0.7.41/STPDF.xcframework.zip", checksum: "caec9359c0aee79f6c8dbff4073cea6040754157f7a1bf28fa0398d613d28030"),
    ]
)
