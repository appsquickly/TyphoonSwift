import PackageDescription

let package = Package(
    name: "TyphoonPackage",
    dependencies: [
            .Package(url: "https://github.com/kylef/Stencil.git", majorVersion: 0, minor: 6)
        ]
)
