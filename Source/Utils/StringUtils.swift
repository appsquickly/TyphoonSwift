//
//  StringUtils.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 15/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation


extension String {
    
    subscript (r: Range<Int>) -> String? { //Optional String as return value
        get {
            let stringCount = self.characters.count as Int
            //Check for out of boundary condition
            if (stringCount < r.endIndex) || (stringCount < r.startIndex){
                return nil
            }
            
            let startIndex = self.startIndex.advancedBy(r.startIndex)
            let endIndex = self.startIndex.advancedBy(r.endIndex)
            
            return self[startIndex..<endIndex]
        }
    }
    
    
    var first: String {
        return String(characters.prefix(1))
    }
    var last: String {
        return String(characters.suffix(1))
    }
    var uppercaseFirst: String {
        return first.uppercaseString + String(characters.dropFirst())
    }
    
    func strip() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}
