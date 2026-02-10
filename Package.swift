// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FloorPlanner",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "FloorPlannerCore",
            targets: ["FloorPlannerCore"]),
    ],
    targets: [
        .target(
            name: "FloorPlannerCore",
            path: "FloorPlanner",
            exclude: ["Info.plist", "FloorPlanner.entitlements"],
            sources: [
                "Models.swift",
                "LayoutEngine.swift",
                "LaminateEngine.swift",
                "TileEngine.swift",
                "PersistenceManager.swift"
            ],
            resources: [
                .process("FloorPlanner.xcdatamodeld")
            ]
        ),
        .testTarget(
            name: "FloorPlannerTests",
            dependencies: ["FloorPlannerCore"]),
    ]
)
