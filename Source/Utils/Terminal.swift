//
//  Terminal.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 23/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation

class Terminal {
    
    static func shell(_ launchPath: String, arguments: [String]) -> String
    {
        let task = NSTask()
        task.launchPath = launchPath
        task.arguments = arguments
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)!
        if output.characters.count > 0 {
            return output.substring(to: output.characters.index(output.endIndex, offsetBy: -1))
            
        }
        return output
    }
    
    static func bash(_ command: String, arguments: [String]) -> String
    {
        let whichPathForCommand = shell("/bin/bash", arguments: [ "-l", "-c", "which \(command)" ])
        return shell(whichPathForCommand, arguments: arguments)
    }
    
}
