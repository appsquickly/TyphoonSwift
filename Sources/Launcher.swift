//
//  Launcher.swift
//  TyphoonPackage
//
//  Created by Aleksey Garbarev on 09/10/2016.
//
//

import Foundation

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
            throw ConfigError.pathNotExists(path: self.config.outputFilePath)
        }
    }
    
    func build() {
        
        enumerateSources(atPath: self.config.inputPath) { source in
            print("source: \(source)")
            
            let time: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
            
            let fileDefinitionBuilder = FileDefinitionBuilder(filePath: source)
            
            
            
//            if let file = fileDefinitionBuilder.build() {
//                
//
//                if file.assemblies.count > 0 {
//                    print("built file \(file)")
//                    //        let generator = FileGenerator(file: file)
//                    //        generator.generate(to: outputPath)
//                }
//                
//            }   
            
            print("elapsed time: \(CFAbsoluteTimeGetCurrent() - time)")
        }

    }
    
    func enumerateSources(withExtension: String = ".swift", atPath: String, block:(String) -> ()) {
        let fileManager = FileManager()
        if let files = try? fileManager.contentsOfDirectory(atPath: atPath) {
            for file in files {
                let fullPath = atPath.appendingPathComponent(file)
                var isDirectory: ObjCBool = false
                fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory)
                if isDirectory.boolValue {
                    enumerateSources(atPath: fullPath, block: block)
                } else if file.hasSuffix(withExtension) {
                    block(fullPath)
                }
            }
        }
    }

    
    
}
