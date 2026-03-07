// swift-tools-version: 5.9
import PackageDescription

let version = "0.9.8"
let repo = "https://github.com/Palerosy/STKit/releases/download/\(version)"

let package = Package(
    name: "STKit",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "STKit", targets: ["STKit"]),
        .library(name: "STDOCX", targets: ["STDOCX", "STKit"]),
        .library(name: "STExcel", targets: ["STExcel", "STKit"]),
        .library(name: "STTXT", targets: ["STTXT", "STKit"]),
        .library(name: "STPDF", targets: ["STPDF", "STKit"]),
    ],
    targets: [
        .binaryTarget(name: "STKit", url: "\(repo)/STKit.xcframework.zip",
                       checksum: "7272141a2722dd4dddf28be53cd16643378b15254eccc2233afb919f2815676e"),
        .binaryTarget(name: "STDOCX", url: "\(repo)/STDOCX.xcframework.zip",
                       checksum: "4dda6c7730dd3bc347d9f845c7aff37daabf6578a2c311f23d3ccfad748f4923"),
        .binaryTarget(name: "STExcel", url: "\(repo)/STExcel.xcframework.zip",
                       checksum: "f2e83d5696b74b32f7bbaccab99937d497ce71a8112d93c703699d1efc2d86c0"),
        .binaryTarget(name: "STTXT", url: "\(repo)/STTXT.xcframework.zip",
                       checksum: "ea8421b87bf37973ec63bca9a6b059b98b43edacb612bff88213ee1bcc0d8f6b"),
        .binaryTarget(name: "STPDF", url: "\(repo)/STPDF.xcframework.zip",
                       checksum: "f9b454f2dc9a5a8fce0e03dff8663aadfd0e17f60856216a63a00af4b1888df3"),
    ]
)
