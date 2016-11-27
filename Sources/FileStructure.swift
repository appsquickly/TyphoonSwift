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
import SourceKittenFramework

class FileStructure {
    
    var structure: (String, JSON)?
    fileprivate var filePath: URL
    
    init(filePathURL: URL) {
        self.filePath = filePathURL
        self.structure = requestStructure()
    }
    
    fileprivate func requestStructure() -> (String, JSON)? {
        
        var text: String, json: JSON
        
        do {
            text = try String(contentsOf: self.filePath, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            
            let structure = SourceKittenFramework.Structure(file: File(contents: text))
            let data = structure.description.data(using: String.Encoding.utf8) as Data!
            
            json = JSON(data!)
        } catch {
            debugPrint("Failed request structure with file path:" + "\(self.filePath.absoluteString)")
            return nil
        }
        
        return (text, json)
    }
}
