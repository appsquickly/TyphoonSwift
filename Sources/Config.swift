//
//  Config.swift
//  TyphoonPackage
//
//  Created by Aleksey Garbarev on 09/10/2016.
//
//

import Foundation

struct Config {
    var inputPath: String
    var outputFilePath: String
    var shouldMonitorChanges: Bool
    var verbose: Bool = false
    
    static func load(fromPath path: String) -> Config? {
        
        var inputPath = ""
        var outputPath = ""
        var verbose = false
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let plist = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as! [String:AnyObject]
            inputPath = plist["assemblesDirPath"] as! String
            outputPath = plist["resultDirPath"] as! String
            verbose = plist["verbose"] as! Bool
        } catch {
            return nil
        }
        
        return Config(inputPath: inputPath, outputFilePath: outputPath, shouldMonitorChanges: true, verbose: verbose)
    }
}
