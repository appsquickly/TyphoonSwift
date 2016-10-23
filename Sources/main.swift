import Foundation

let env = ProcessInfo.processInfo.environment

var inputPath = env["example_input_path"] ?? ""
var outputPath = env["example_output_path"] ?? ""


var config = Config(inputPath: inputPath,
                    outputFilePath: outputPath,
                    shouldMonitorChanges: true)

do {
    let launcher = try Launcher(withConfig: config)
    launcher.run()
} catch ConfigError.pathNotExists(let incorrectPath) {
    print("Path is not correct: \(incorrectPath)")
}





