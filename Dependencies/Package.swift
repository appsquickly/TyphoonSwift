import PackageDescription

let package = Package(
    name: "TyphoonSwiftDependencies",
    dependencies: [
            .Package(url: "https://github.com/kylef/Stencil.git", majorVersion: 0, minor: 6),
            .Package(url: "https://github.com/vasilenkoigor/Witness", majorVersion: 0, minor: 4)
        ]
)
