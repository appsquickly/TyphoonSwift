////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON FRAMEWORK
//  Copyright 2016, TyphoonSwift Framework Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////

import Foundation

class FileStructure {
    
    var content: (String, JSON)?
    fileprivate var filePath: URL
    
    init(filePath: String) {
        self.filePath = URL(fileURLWithPath: filePath)
        self.content = loadFile()
    }
    
    fileprivate func loadFile() -> (String, JSON)? {
        var text: String, json: JSON
        
        do {
            text = try String(contentsOf: self.filePath, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            let parsedString = Terminal.bash("/usr/local/bin/sourcekitten", arguments: ["structure", "--text", text])
            json = jsonFromString(parsedString)!
        } catch {
            return nil
        }
        
        return (text, json)
    }
    
    fileprivate func jsonFromString(_ string: String) -> JSON? {
        let data = string.data(using: String.Encoding.utf8) as Data!
        let json = JSON(data)
        return json
    }
}
