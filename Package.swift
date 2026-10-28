// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Taskerz",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Taskerz",
            path: "Sources/Taskerz"
        )
    ]
)
