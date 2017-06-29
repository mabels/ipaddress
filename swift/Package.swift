import PackageDescription

let package = Package(
    name: "IpAddress",
    targets: [],
    dependencies: [
      .Package(url: "https://github.com/lorentey/BigInt.git", majorVersion: 2, minor: 2)
    ]
)
