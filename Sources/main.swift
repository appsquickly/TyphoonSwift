import Foundation

let typhoonSwift = TyphoonPackage()
print(typhoonSwift.description)

let task = Process()
print(task)

let fileDefinition = FileDefinition(fileName: "testFile")
print(fileDefinition.fileName)

var config = Config(inputPath: "/Users/alex/Development/typhoon-swift/",
                    outputFilePath: "/Users/alex/Desktop/output.swift",
                    shouldMonitorChanges: false)

//config.inputPath = "/Users/alex/Desktop/TyphoonTestProject/TyphoonTestProject/Assemblies"
//config.outputFilePath = "/Users/alex/Desktop/TyphoonTestProject/TyphoonTestProject/TyphoonOutput/typhoon.swift"

do {
    let launcher = try Launcher(withConfig: config)
    launcher.run()
} catch ConfigError.pathNotExists(let incorrectPath) {
    print("Path is not correct: \(incorrectPath)")
}





