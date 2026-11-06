// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NotasRapidas",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "NotasCore"),
        .executableTarget(name: "NotasRapidas", dependencies: ["NotasCore"]),
        .testTarget(name: "NotasCoreTests", dependencies: ["NotasCore"]),
    ]
)
