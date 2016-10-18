import PackageDescription

let package = Package(
  name: "Stencil",
  dependencies: [
    .Package(url: "https://github.com/kylef/PathKit.git", majorVersion: 0, minor: 7),

    // https://github.com/apple/swift-package-manager/pull/597
    .Package(url: "https://github.com/kylef/Spectre", majorVersion: 0, minor: 7),
  ]
)
