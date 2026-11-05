// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "focussi",
    platforms: [.macOS(.v13), .iOS(.v17)],
    products: [
        .library(name: "FocusCore", targets: ["FocusCore"]),
        .executable(name: "FocusCoreChecks", targets: ["FocusCoreChecks"])
    ],
    targets: [
        .target(name: "FocusCore"),
        // Standalone checks also run on Macs with Command Line Tools only.
        .executableTarget(name: "FocusCoreChecks", dependencies: ["FocusCore"], path: "Tests/FocusCoreTests")
    ]
)
