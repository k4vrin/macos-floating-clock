// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NotchClock",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "NotchClock", targets: ["NotchClock"])],
    targets: [
        .executableTarget(name: "NotchClock"),
        .testTarget(name: "NotchClockTests", dependencies: ["NotchClock"])
    ],
    swiftLanguageModes: [.v6]
)
