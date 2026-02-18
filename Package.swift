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
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.8/STKit.xcframework.zip",
            checksum: "2bd0a28ea10d3ca56f80603572f448aa8092c91fb8dac203ddf19729e8eefc99"
        ),
        .binaryTarget(
            name: "STDOCX",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.8/STDOCX.xcframework.zip",
            checksum: "dffb65356ec89a2a4969d694ed7cef9aada0e3a2c54f8a79f3e5f711c91cdc54"
        ),
        .binaryTarget(
            name: "STExcel",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.8/STExcel.xcframework.zip",
            checksum: "925d11185cc376636c30bd40cb7dd5b9e17214a08609b6e51aed5946923e5ec4"
        ),
        .binaryTarget(
            name: "STTXT",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.8/STTXT.xcframework.zip",
            checksum: "0aa7b69bf0afca963bf20870043db44583561502de750beda63fd00ab497d2f8"
        ),
        .binaryTarget(
            name: "_ZIPFoundation",
            url: "https://github.com/Palerosy/STKit/releases/download/0.7.8/_ZIPFoundation.xcframework.zip",
            checksum: "6746dc319dd23cf77b77a7c6d086adb20ab9433851bf6fa0c8897776a478b979"
        ),
    ]
)
