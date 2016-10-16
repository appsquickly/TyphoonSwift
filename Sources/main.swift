import Foundation

var config = Config(inputPath: "/Users/alex/Development/typhoon-swift/",
                    outputFilePath: "/Users/alex/Desktop/output.swift",
                    shouldMonitorChanges: false)

do {
    let launcher = try Launcher(withConfig: config)
    launcher.run()
} catch ConfigError.pathNotExists(let incorrectPath) {
    print("Path is not correct: \(incorrectPath)")
}





