// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ReminderCards",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ReminderCards",
            targets: ["ReminderCards"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "6.0.0")
    ],
    targets: [
        .target(
            name: "ReminderCards",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ])
    ]
)

