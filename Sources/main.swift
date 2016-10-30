import Foundation





let fileManager = FileManager.default

let env = ProcessInfo.processInfo.environment
let currentPath = env["PWD"] ?? ""

let arguments = CommandLine.arguments

print("arguments: \(arguments)")

func loadConfig() -> Config? {
    
    let configPath = "\(currentPath)/Typhoon.plist"
    
    var inputPath = ""
    var outputPath = ""
    
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
        let plist = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as! [String:AnyObject]
        
        inputPath = plist["assemblesDirPath"] as! String
        outputPath = plist["resultDirPath"] as! String
    } catch {
        return nil
    }
    
    let config = Config(inputPath: inputPath,
                        outputFilePath: outputPath,
                        shouldMonitorChanges: true)
    
    return config
}

if arguments.contains("setup")
{
    var sourcesPath = ""
    var defaultInputPath = ""
    var defaultOutputPath = ""
    
    for path in try! fileManager.contentsOfDirectory(atPath: currentPath) {
        if path.hasSuffix("xcodeproj") || path.hasSuffix("xcworkspace") {
            var url = URL(fileURLWithPath: path)
            url.deletePathExtension()
            if fileManager.fileExists(atPath: url.path) {
                sourcesPath = url.path
                defaultInputPath = "\(url.relativePath)/Assemblies"
                defaultOutputPath = "\(url.relativePath)/Typhoon"
            }
        }
    }
    
    print("Enter directory where your assemblies would be placed? (\(defaultInputPath))")
    var inputDirectory = readLine(strippingNewline: true)!
    if inputDirectory == "" {
        inputDirectory = defaultInputPath
    }
    
    print("Enter directory where activated assemblies and Typhoon sources would be placed? (\(defaultOutputPath))")
    var outputDirectory = readLine(strippingNewline: true)!
    if outputDirectory == "" {
        outputDirectory = defaultOutputPath
    }
    
    let configList = [ "assemblesDirPath": inputDirectory, "resultDirPath": outputDirectory ]
    
    let data = try! PropertyListSerialization.data(fromPropertyList: configList, format: .xml, options: PropertyListSerialization.WriteOptions.allZeros)
    
    try! data.write(to: URL(fileURLWithPath: "Typhoon.plist"))
    
    print("Typhoon configured successfully. Try run `typhoon run` now")
    
}

if arguments.contains("run")
{
    if let config = loadConfig() {
        do {
            let launcher = try Launcher(withConfig: config)
            launcher.run()
        } catch ConfigError.pathNotExists(let incorrectPath) {
            print("Path is not correct: '\(incorrectPath)'")
        }
    } else {
        print("Typhoon is not configured for this project. Run `typhoon setup` first")
    }
    
}



