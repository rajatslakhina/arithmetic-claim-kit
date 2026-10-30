// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "ArithmeticClaimKit",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(name: "ArithmeticClaimKit", targets: ["ArithmeticClaimKit"]),
        .executable(name: "ArithmeticClaimDemo", targets: ["ArithmeticClaimDemo"])
    ],
    targets: [
        .target(name: "ArithmeticClaimKit"),
        .executableTarget(
            name: "ArithmeticClaimDemo",
            dependencies: ["ArithmeticClaimKit"]
        ),
        .testTarget(
            name: "ArithmeticClaimKitTests",
            dependencies: ["ArithmeticClaimKit"]
        )
    ],
    swiftLanguageModes: [.v6]
)
