// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "IpAddress",
    dependencies: [
      .package(url: "https://github.com/attaswift/BigInt.git", from: "5.2.1")
    ],
    targets: [
	.target(
            name: "IpAddress",
            dependencies: ["BigInt"]),
        .testTarget(
            name: "IpAddressTests",
            dependencies: ["BigInt", "IpAddress"])
    ]
)
