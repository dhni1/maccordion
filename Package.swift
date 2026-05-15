// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Maccordion",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Maccordion", targets: ["Maccordion"])
    ],
    targets: [
        .executableTarget(
            name: "Maccordion",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreFoundation"),
                .linkedFramework("IOKit")
            ]
        )
    ]
)
