//
//  Launcher.swift
//  TyphoonPackage
//
//  Created by Aleksey Garbarev on 09/10/2016.
//
//

import Foundation
import Witness

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
        build()
        if config.shouldMonitorChanges {
            self.monitor = Witness(paths: [config.inputPath], flags: .FileEvents, latency: 0.3) { events in
                print("file system events received: \(events)")
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
    
    func build() {
        
        var assemblies: [AssemblyDefinition] = []
        
        enumerateSources(atPath: self.config.inputPath) { source in
//            print("source: \(source)")
//            let time: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
            
            let fileDefinitionBuilder = FileDefinitionBuilder(filePath: source)
            
            if let file = fileDefinitionBuilder.build() {
                assemblies.append(contentsOf: file.assemblies)
            }
//            print("elapsed time: \(CFAbsoluteTimeGetCurrent() - time)")
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
    
    
    
}
