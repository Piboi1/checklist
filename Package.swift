// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Checklist",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Checklist", path: "Sources/Checklist"),
    ]
)
