// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "AudioTalkApp",
  platforms: [ .macOS(.v13) ],
  products: [
    .executable(name: "AudioTalkApp", targets: ["AudioTalkApp"]) 
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.58.0")
  ],
  targets: [
    .executableTarget(
      name: "AudioTalkApp",
      dependencies: [
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOPosix", package: "swift-nio"),
        .product(name: "NIOHTTP1", package: "swift-nio")
      ]
    )
  ]
)

