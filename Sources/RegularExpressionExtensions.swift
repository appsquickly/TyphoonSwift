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

extension NSRegularExpression {
    
    convenience init?(pattern: String) {
        do {
            try self.init(pattern: pattern, options: NSRegularExpression.Options.init(rawValue: 0))
        } catch {
            fatalError("Error: Can't create regular expression")
        }
    }
    
    func matchedGroup(insideString: String, groupIndex: Int = 0, matchIndex: Int = 0) -> String? {
        
        let stringRange = insideString.lengthOfBytes(using: String.Encoding.utf8)
        
        let matches = self.matches(in: insideString, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, stringRange))
        
        if matches.count > matchIndex {
            let match = matches[matchIndex]
            if match.numberOfRanges > groupIndex + 1 {
                return insideString[match.rangeAt(groupIndex + 1).toRange()!]
            }
        }
        return nil
    }
    
    class func matchedGroup(pattern: String, insideString: String, groupIndex: Int = 0, matchIndex: Int = 0) -> String? {
        
        let regexp = NSRegularExpression(pattern: pattern)!
        let stringRange = insideString.lengthOfBytes(using: String.Encoding.utf8)
        
        let matches = regexp.matches(in: insideString, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, stringRange))
        
        if matches.count > matchIndex {
            let match = matches[matchIndex]
            if match.numberOfRanges > groupIndex + 1 {
                return insideString[match.rangeAt(groupIndex + 1).toRange()!]
            }
        }
        return nil
    }
}
