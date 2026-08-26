// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Voxyz",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "VoxyzCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Voxyz",
            exclude: ["Resources", "Info.plist"]
        ),
    ]
)
