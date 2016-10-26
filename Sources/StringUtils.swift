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
            if (stringCount < r.upperBound) || (stringCount < r.lowerBound){
                return nil
            }
            
            let startIndex = self.characters.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.characters.index(self.startIndex, offsetBy: r.upperBound)
            
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
        return first.uppercased() + String(characters.dropFirst())
    }
    
    func strip() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    func appendingPathComponent(_ string: String) -> String {
        return URL(fileURLWithPath: self).appendingPathComponent(string).path
    }
    
    func lastPathComponent() -> String {
        return URL(fileURLWithPath: self).lastPathComponent
    }
    
    
    func stringByReplacingFirstOccurrenceOfString(target: String, withString replaceString: String) -> String {
        if let range = self.range(of: target) {
            var string = self
            string.replaceSubrange(range, with: replaceString)
            return string
        }
        return self
    }
    
    func enumerateParams(usingBlock block: (String, Int)->())  {
        
        var regexp: NSRegularExpression
        do {
            regexp = try NSRegularExpression(pattern: "([^(]*?:)", options: NSRegularExpression.Options.init(rawValue: 0))
        } catch {
            print("Error: Can't create regexpt to march return type from method")
            return
        }
        let matches = regexp.matches(in: self, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, self.lengthOfBytes(using: String.Encoding.utf8)))
        
        var index = 0
        for match in matches {
            let range = match.rangeAt(1).toRange()
            if let string = self[range!] {
                block(string, index)
            }
            index += 1
        }
    }
    
    func numberOfSelectorParams() -> Int {
        var number : Int = 0
        self.enumerateParams { param, index in
            number += 1
        }
        return number
    }
    
}
