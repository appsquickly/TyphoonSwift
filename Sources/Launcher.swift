//
//  Launcher.swift
//  TyphoonPackage
//
//  Created by Aleksey Garbarev on 09/10/2016.
//
//

import Foundation
import Witness
import PathKit

enum ConfigError : Error {
    case pathNotExists(path: String)
}

class Launcher {
    
    var config: Config!
    var monitor: Witness?
    
    init(withConfig config:Config) throws {
        self.config = config
        try validateConfig()
    }
    
    func run() {
        prepareToRun()
        build()
        if config.shouldMonitorChanges {
            log("Monitoring filesystem changes in \(config.inputPath)")
            self.monitor = Witness(paths: [config.inputPath], flags: .FileEvents, latency: 0.3) { events in
                self.build()
            }
            RunLoop.current.run()
        }
    }
    
    func validateConfig() throws {
        let fileManager = FileManager()
        if !fileManager.fileExists(atPath: self.config.inputPath) {
            throw ConfigError.pathNotExists(path: self.config.inputPath)
        }
        if !fileManager.fileExists(atPath: self.config.outputFilePath) {
            try fileManager.createDirectory(atPath: self.config.outputFilePath, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    func prepareToRun() {
        log("Running in verbose mode!")
        copyRuntime()
    }
    
    func copyRuntime() {
        let fileManager = FileManager.default
        
        let sourceDirectory = "\(ResourceDir)/Runtime"
        let destinationDirectory = "\(config.outputFilePath)/Runtime"
        
        do {
            try? fileManager.removeItem(atPath: destinationDirectory)
            try? fileManager.createDirectory(atPath: destinationDirectory, withIntermediateDirectories: true, attributes: nil)
            
            for fileName in try fileManager.contentsOfDirectory(atPath: sourceDirectory) {
                try fileManager.copyItem(atPath: "\(sourceDirectory)/\(fileName)", toPath: "\(destinationDirectory)/\(fileName)")
            }
        } catch {
            print("Error while coping runtime: \(error)")
        }
        
        log("Runtime copied")
    }
    
    func build() {
        var assemblies: [AssemblyDefinition] = []
        
        enumerateSources(atPath: self.config.inputPath) { source in
            let time: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
            let fileDefinitionBuilder = FileDefinitionBuilder(filePath: source)
            if let file = fileDefinitionBuilder.build() {
                assemblies.append(contentsOf: file.assemblies)
            }
            log("\(Path(source).lastComponent) | processed : \(CFAbsoluteTimeGetCurrent() - time)")
        }
        
        let resultFile = FileDefinition(fileName: "assemblies.swift")
        resultFile.assemblies = assemblies
        
        let generator = FileGenerator(file: resultFile)
        generator.generate(to: "\(self.config.outputFilePath)/assemblies.swift")
    }
    
    func enumerateSources(withExtension suffix: String = ".swift", atPath path: String, block:(String) -> ()) {
        let fileManager = FileManager()
        
        var isDirectory: ObjCBool = false
        fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        
        if isDirectory.boolValue {
            if let files = try? fileManager.contentsOfDirectory(atPath: path) {
                for file in files {
                    enumerateSources(withExtension: suffix, atPath: path.appendingPathComponent(file), block: block)
                }
            }
        }
        else if path.hasSuffix(suffix) {
            block(path)
        }
    }
    
    
    fileprivate func log(_ text: String) {
        if config.verbose {
            print(text)
        }
    }
    
    
}
