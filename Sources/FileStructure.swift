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
    
    var structure: (String, JSON)?
    fileprivate var filePath: URL
    
    init(filePath: String) {
        self.filePath = URL(fileURLWithPath: filePath)
        self.structure = requestStructure()
    }
    
    fileprivate func requestStructure() -> (String, JSON)? {
        
        var text: String, json: JSON
        
        do {
            text = try String(contentsOf: self.filePath, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            let parsedString = Terminal.bash("/usr/local/bin/sourcekitten", arguments: ["structure", "--text", text])
            let data = parsedString.data(using: String.Encoding.utf8) as Data!
            json = JSON(data)
        } catch {
            debugPrint("Failed request structure with file path:" + "\(self.filePath.absoluteString)")
            return nil
        }
        
        return (text, json)
    }
}
