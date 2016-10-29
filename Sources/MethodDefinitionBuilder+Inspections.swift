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

extension MethodDefinitionBuilder {
    
    func isReturn(beforeLocation location:Int) -> Bool {
        
        var regexp: NSRegularExpression
        do {
            regexp = try NSRegularExpression(pattern: "return\\s*$", options: NSRegularExpression.Options.init(rawValue: 0))
        } catch {
            print("Error: Can't create regexpt to march return type from method")
            return false
        }
        let matches = regexp.matches(in: methodBody, options: NSRegularExpression.MatchingOptions.init(rawValue:0), range: NSMakeRange(0, location))
        return matches.count == 1
    }
    
    func isReturn(withIvar ivarName:String) -> Bool {
        
        var regexp: NSRegularExpression
        do {
            regexp = try NSRegularExpression(pattern: "return\\s+\(ivarName)", options: NSRegularExpression.Options.init(rawValue: 0))
        } catch {
            print("Error: Can't create regexpt to march return type from method")
            return false
        }
        
        let stringRange = methodBody.lengthOfBytes(using: String.Encoding.utf8)
        return regexp.matches(in: methodBody, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, stringRange)).count == 1
        
    }
    
    func isBlockParameter(_ parameter: JSON, parameterName: String) -> Bool {
        let isEmpty = parameter[SwiftDocKey.nameLength].integer == 0 && parameter[SwiftDocKey.nameOffset].integer == 0
        return isEmpty || parameter[SwiftDocKey.name].string == parameterName
    }
    
    func isMultilineBlockParameter(_ parameter: JSON) -> Bool {
        if let blockHead = parameter[SwiftDocKey.substructure].array {
            for item in blockHead  {
                if item[SwiftDocKey.kind].string == SourceLang.Statement.brace {
                    return true
                }
            }
        }
        return false
    }
    
    func isTyphoonDefinition() -> Bool {
        let length = (self.node[SwiftDocKey.bodyOffset].integer!) - (self.node[SwiftDocKey.nameOffset].integer!)
        let returnValue = content(from: self.node[SwiftDocKey.nameOffset].integer!, length: length) as String!
        
        let wholeRange = NSMakeRange(0, length)
        
        if let regexp = definitionRegexp {
            return regexp.matches(in: returnValue!, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: wholeRange ).count > 0
        } else {
            return false
        }
    }
    
    func isCallNode(_ callNode: JSON, matchesParamNames paramNames: [String]) -> Bool {
        if (paramNames.count == 0) {
            return true
        } else if (callNode[SwiftDocKey.substructure] != nil) {
            var paramsCorrect = true
            let params = callNode[SwiftDocKey.substructure].array!
            
            if (params.count < paramNames.count) {
                return false
            }
            
            let minCount = min(paramNames.count, params.count)
            for index in 0..<minCount {
                if let kind = params[index][SwiftDocKey.kind].string {
                    if kind == SourceLang.Declaration.varParameter {
                        if let name = params[index][SwiftDocKey.name].string {
                            if name != paramNames[index] {
                                paramsCorrect = false
                                break
                            }
                        } else {
                            // If name is empty = block or something
                            paramsCorrect = false
                            break
                        }
                    } else {
                        // If not parameter - skip it
                    }
                } else {
                    print("Can't use kind as string")
                    // Can't use 'key.kind' as String
                }
            }
            return paramsCorrect
        }
        return false
    }
}
