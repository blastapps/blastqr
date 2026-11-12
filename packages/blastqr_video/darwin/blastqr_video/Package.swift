// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "blastqr_video",
  platforms: [
    .iOS("15.0"),
    .macOS("12.0"),
  ],
  products: [
    .library(name: "blastqr-video", targets: ["blastqr_video"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "blastqr_video",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ]
    )
  ]
)
