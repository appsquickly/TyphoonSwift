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

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}



enum DefinitionBuilderError: Error {
    case invalidBlockNode
}

class MethodDefinitionBuilder {
    
    var source: String!
    var node: NSDictionary!
    
    var methodBody: String!
    
    convenience init(source: String, node: NSDictionary) {
        self.init()
        self.source = source
        self.node = node
        
        self.methodBody = content(from: self.node[SwiftDocKey.bodyOffset], length: self.node[SwiftDocKey.bodyLength]) as String!
    }
    
    func build() -> MethodDefinition? {
        
        if (!isTyphoonDefinition()) {
            return nil
        } else {
            let name = content(from: self.node[SwiftDocKey.nameOffset], length: self.node[SwiftDocKey.nameLength]) as String!
            let methodOffset = self.node[SwiftDocKey.bodyOffset] as! Int
            
            let methodDefinition = MethodDefinition(name: name!, originalSource: self.methodBody)
            parseArgumentsForMethod(methodDefinition)
            
            let key = keyFromMethodName(self.node[SwiftDocKey.name] as! String)
            
            if let definitionCalls = findCalls("Definition", methodName: "withClass") {
                for call in definitionCalls {
                    let (definition, isResult) = instanceDefinition(fromCall: call, methodOffset: methodOffset, key: key)
                    methodDefinition.addDefinition(definition)
                    if isResult {
                        methodDefinition.returnDefinition = definition
                    }
                }
            }
            return methodDefinition
        }
    }
    
    func regexpForPattern(_ pattern: String) -> NSRegularExpression
    {
        var regexp: NSRegularExpression
        do {
            regexp = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.init(rawValue: 0))
        } catch {
            fatalError("Error: Can't create regexpt")
        }
        return regexp
    }
    
    func matchedGroup(pattern: String, insideString: String, groupIndex:Int = 0, matchIndex:Int = 0) -> String?
    {
        let regexp = regexpForPattern(pattern)
        
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
    
    func parseArgumentsForMethod(_ method: MethodDefinition)
    {
        if method.numberOfRuntimeArguments() > 0 {
            
            let name = method.name!.replacingOccurrences(of: "\n", with: "")
            let content = matchedGroup(pattern: "\\((.*)\\)", insideString: name) as String!
            let argStrings = content?.components(separatedBy: ",")
            
            var arguments: [MethodDefinition.Argument] = []
            
            
            for argumentString in argStrings! {
                
                var argument = MethodDefinition.Argument()
                
                let argumentComponents = argumentString.components(separatedBy: ":")
                
                //Parse type and default value
                let typePart = argumentComponents[1].strip()
                if typePart.contains("=") {
                    let typeComponents = typePart.components(separatedBy: "=")
                    argument.type = typeComponents[0].strip()
                    argument.defaultValue = typeComponents[1].strip()
                } else {
                    argument.type = typePart
                }
                
                //Parse name, label and attributes
                var names = argumentComponents[0].strip().components(separatedBy: " ")
                argument.ivar = names.popLast() as String!
                
                if let label = names.popLast() {
                    if label == "inout" {
                        argument.attributes.append(label)
                    } else if label != "_" {
                        argument.label = label
                    }
                }
                arguments.append(argument)
                
                print("Arg: \(argument)")
                
            }
            print("\n")
        }
        
        
    }
    
    func instanceDefinition(fromCall call: NSDictionary, methodOffset: Int, key: String) -> (InstanceDefinition, Bool)
    {
        let definition = InstanceDefinition()
        definition.className = typeFromDefinitionCall(call)
        definition.range = makeRange(call, offset: methodOffset)
        definition.key = key
        
        let isResult = getDefinitionConfigurationFromCall(call, methodOffset: methodOffset) { content, ivarName, isExternal in
            
            let properties = self.propertyInjectionsFromContent(content, ivar: ivarName, contentOffset: methodOffset)
            if isExternal {
                _ = properties.map { property in
                    property.external = true
                }
            }
            definition.add(properties)
            
            if let scope = self.scopeFromContent(content, ivar: ivarName) {
                definition.scope = scope
            }
        }
        
        return (definition, isResult)
    }
    
    func getDefinitionConfigurationFromCall(_ call: NSDictionary, methodOffset: Int, contentHandler: ([NSDictionary], String, Bool) -> ()) -> Bool
    {
        if let configuration = configurationBlock(call, offset: methodOffset) {
            contentHandler(configuration.content, configuration.firstArgumentName, false)
        }
        
        var isResult = false
        
        let callOffset = call[SwiftDocKey.offset] as! Int - methodOffset
        
        if let ivarName = ivarAssignment(beforeLocation: callOffset) {
            
            isResult = isReturn(withIvar: ivarName)
            
            if let content = self.node[SwiftDocKey.substructure] as? [NSDictionary] {
                contentHandler(content, ivarName, true)
            }
            
        } else {
            isResult = isReturn(beforeLocation: callOffset)
        }
        
        return isResult
    }
    
    func ivarAssignment(beforeLocation location:Int) -> String?
    {
        var regexp: NSRegularExpression
        do {
            regexp = try NSRegularExpression(pattern: "\\s+(\\w*)\\s+=\\s+$", options: NSRegularExpression.Options.init(rawValue: 0))
        } catch {
            print("Error: Can't create regexpt to march return type from method")
            return nil
        }
        let matches = regexp.matches(in: methodBody, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, location))
        if matches.count == 1 {
            let match = matches.first!
            return methodBody[match.rangeAt(1).toRange()!]
        }
        
        return nil
    }
    
    func isReturn(beforeLocation location:Int) -> Bool
    {
        var regexp: NSRegularExpression
        do {
            regexp = try NSRegularExpression(pattern: "return\\s*$", options: NSRegularExpression.Options.init(rawValue: 0))
        } catch {
            print("Error: Can't create regexpt to march return type from method")
            return false
        }
        return regexp.matches(in: methodBody, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, location)).count == 1
    }
    
    func isReturn(withIvar ivarName:String) -> Bool
    {
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
    
    func configurationBlock(_ fromCall: NSDictionary, offset: Int) -> BlockNode?
    {
        do {
            //            print("Trying to get block from call \(fromCall)")
            if let configurationBlock = try blockFromCall(fromCall, argumentName: "configuration", offset: offset) {
                return configurationBlock
            }
        } catch {
            print("Error while getting configuration block")
        }
        return nil
        
    }
    
    func propertyInjectionsFromBlock(_ block: BlockNode, methodOffset: Int) -> [PropertyInjection]
    {
        let blockOffset = block.range.first!
        
        print("Trying to get properties for \(block.firstArgumentName)")
        
        return propertyInjectionsFromContent(block.content, ivar: block.firstArgumentName, contentOffset: methodOffset + blockOffset)
    }
    
    func scopeFromContent(_ contents: [NSDictionary], ivar: String) -> Definition.Scope?
    {
        var scope : Definition.Scope? = nil
        
        for item in contents {
            if let name = item[SwiftDocKey.name] as? String {
                switch name {
                case "\(ivar).setScope":
                    if let stirng = content(makeRange(item, parameter: "body")) {
                        scope = Definition.Scope.fromString(stirng)
                    }
                default: break
                }
            }
        }
        
        return scope
    }
    
    func propertyInjectionsFromContent(_ content: [NSDictionary], ivar: String, contentOffset: Int) -> [PropertyInjection]
    {
        var injections :[PropertyInjection] = []
        
        for item in content {
            if let name = item[SwiftDocKey.name] as? String {
                switch name {
                case "\(ivar).injectProperty":
                    let property = propertyInjectionFromParameter(item, offset: contentOffset)
                    injections.append(property)
                default: break
                    
                }
            }
        }
        
        return injections
    }
    
    func propertyInjectionFromParameter(_ parameter: NSDictionary, offset: Int) -> PropertyInjection
    {
        let params = parameter[SwiftDocKey.substructure] as! [NSDictionary]
        
        let propertyRawName = content(from: params[0][SwiftDocKey.bodyOffset], length: params[0][SwiftDocKey.bodyLength]) as String!
        let propertyName = propertyRawName?.replacingOccurrences(of: "\"", with: "")
        
        let injectedValue = content(from: params[1][SwiftDocKey.bodyOffset], length: params[1][SwiftDocKey.bodyLength]) as String!
        
        let injection = PropertyInjection(propertyName: propertyName!, injectedValue: injectedValue!)
        injection.range = makeRange(parameter, offset: offset)
        
        return injection
    }
    
    func blockFromCall(_ fromCall: NSDictionary, argumentIndex: ArgumentIndex = ArgumentIndex.last, argumentName: String, offset: Int) throws -> BlockNode?
    {
        if let blockParameter = parameterFromCall(fromCall, atIndex: argumentIndex) {
            
            if !isBlockParameter(blockParameter, parameterName:  argumentName) {
                return nil
            }
            
            let block = BlockNode()
            
            if isMultilineBlockParameter(blockParameter) {
                let header = blockParameter[SwiftDocKey.substructure] as! [NSDictionary]
                for item in header {
                    let kind = item[SwiftDocKey.kind] as! String
                    switch kind {
                    case SourceLang.Declaration.varParameter:
                        if let name = item[SwiftDocKey.name] as? String {
                            block.argumentNames.append(name)
                        }
                    case SourceLang.Statement.brace:
                        if let blockContent = item[SwiftDocKey.substructure] as? [NSDictionary] {
                            block.content = blockContent
                            block.range = makeRange(item, parameter: "body", offset: offset)
                            block.source = content(block.range, offset: offset)
                        } else {
                            return nil
                        }
                    default:
                        throw DefinitionBuilderError.invalidBlockNode
                    }
                }
            } else {
                
                //Check for parameters
                var substructure = blockParameter[SwiftDocKey.substructure] as! [NSDictionary]
                for (index, item) in substructure.enumerated() {
                    switch item[SwiftDocKey.kind] as! String {
                    case SourceLang.Declaration.varParameter:
                        if let name = item[SwiftDocKey.name] as? String {
                            block.argumentNames.append(name)
                            substructure.remove(at: index)
                        }
                    default: break
                    }
                }
                
                block.content = substructure
                block.range = makeRange(blockParameter, parameter: "body", offset: offset)
                block.source = content(block.range, offset: offset)
            }
            
            
            return block
        } else {
            return nil
        }
    }
    
    func isBlockParameter(_ parameter: NSDictionary, parameterName: String) -> Bool
    {
        let isEmpty = parameter[SwiftDocKey.nameLength] as! Int == 0 && parameter[SwiftDocKey.nameOffset] as! Int == 0
        return isEmpty || parameter[SwiftDocKey.name] as! String == parameterName
    }
    
    func isMultilineBlockParameter(_ parameter: NSDictionary) -> Bool
    {
        if let blockHead = parameter[SwiftDocKey.substructure] as? [NSDictionary] {
            for item in blockHead  {
                if item[SwiftDocKey.kind] as? String == SourceLang.Statement.brace {
                    return true
                }
            }
        }
        return false
    }
    
    func parameterFromCall(_ call: NSDictionary, atIndex: ArgumentIndex) -> NSDictionary?
    {
        var argumentIndex :Int = 0
        let array = call[SwiftDocKey.substructure] as! [NSDictionary]
        
        switch atIndex {
        case .index(let index):
            argumentIndex = index
        case .last:
            argumentIndex = array.count - 1
        }
        
        if argumentIndex > array.count - 1 || argumentIndex < 0 {
            return nil
        } else {
            return array[argumentIndex]
        }
    }
    
    /**
     * Returns method call with specified caller and at least one method coincidence.
     * For example if caller is "Definition" and methodName is "withClass", then both "withClass" and "withClass, configuration"
     * will be captured
     */
    func findCalls(_ caller: String, methodName :String...) -> Array<NSDictionary>?
    {
        var array = Array<NSDictionary>()
        findCalls(self.node, toArray: &array, caller: caller, methodNames: methodName)
        return array
    }
    
    func findCalls(_ insideDictionary: NSDictionary, toArray: inout Array<NSDictionary>, caller: String, methodNames: [String])
    {
        enumerateDictionaries(inside: insideDictionary) { (item, shouldStop) in
            if (item[SwiftDocKey.kind] != nil && item[SwiftDocKey.kind] as! String == SourceLang.Expr.call) {
                if (item[SwiftDocKey.name] as! String == caller && self.isCallNode(item, matchesParamNames: methodNames)) {
                    toArray.append(item)
                }
            }
        }
    }
    
    func isCallNode(_ callNode: NSDictionary, matchesParamNames paramNames: [String]) -> Bool
    {
        if (paramNames.count == 0) {
            return true
        } else if (callNode[SwiftDocKey.substructure] != nil) {
            var paramsCorrect = true
            let params = callNode[SwiftDocKey.substructure] as! [NSDictionary]
            
            if (params.count < paramNames.count) {
                return false
            }
            
            let minCount = min(paramNames.count, params.count)
            for index in 0..<minCount {
                if let kind = params[index][SwiftDocKey.kind] as? String {
                    if kind == SourceLang.Declaration.varParameter {
                        if let name = params[index][SwiftDocKey.name] as? String {
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
                        print("No parameter name - skip it")
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
    
    func parameterWithName(_ name: String, fromCall call:NSDictionary) -> NSDictionary?
    {
        if (call[SwiftDocKey.substructure] != nil) {
            for item in call[SwiftDocKey.substructure] as! [NSDictionary] {
                if item[SwiftDocKey.kind] as? String == SourceLang.Declaration.varParameter {
                    if (item[SwiftDocKey.name] as? String == name) {
                        return item
                    }
                }
            }
        }
        return nil
    }
    
    func typeFromDefinitionCall(_ callNode: NSDictionary) -> String
    {
        if let classParam = parameterWithName("withClass", fromCall: callNode) {
            
            let rawType = content(from: classParam[SwiftDocKey.bodyOffset], length: classParam[SwiftDocKey.bodyLength])!
            
            return rawType.replacingOccurrences(of: ".self", with: "")
        } else {
            return ""
        }
    }
    
    func isTyphoonDefinition() -> Bool
    {
        createReturnTypeRegexpIfNeeded()
        
        let length = (self.node[SwiftDocKey.bodyOffset] as! Int!) - (self.node[SwiftDocKey.nameOffset] as! Int!)
        let returnValue = content(from: self.node[SwiftDocKey.nameOffset], length: length) as String!
        
        let wholeRange = NSMakeRange(0, length)
        
        return MethodDefinitionBuilder.definitionRegexp?.matches(in: returnValue!, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: wholeRange ).count > 0
    }
    
    ///////////////////////////////////////////////////
    ///////////////////// PRIVATE /////////////////////
    ///////////////////////////////////////////////////
    
    
    fileprivate func keyFromMethodName(_ name: String) -> String
    {
        return name.replacingOccurrences(of: "[_\\(\\)]", with: "", options: NSString.CompareOptions.regularExpression, range: nil)
    }
    
    static var definitionRegexp: NSRegularExpression?
    
    fileprivate func createReturnTypeRegexpIfNeeded()
    {
        if (MethodDefinitionBuilder.definitionRegexp == nil) {
            do {
                MethodDefinitionBuilder.definitionRegexp = try NSRegularExpression(pattern: "->\\s*?(Definition)\\s*?\\{", options: NSRegularExpression.Options.init(rawValue: 0))
            } catch {
                print("Error: Can't create regexpt to march return type from method")
            }
        }
    }
    
    fileprivate func content(from startLocation: Any?, length: Any?) -> String?
    {
        let start = startLocation as! Int
        let end = (length as! Int) + start
        
        return source[start..<end]
    }
    
    fileprivate func content(_ r: CountableRange<Int>, offset: Int = 0) -> String?
    {
        var countableRange = r
        if (offset > 0) {
            countableRange = r.lowerBound.advanced(by: offset)..<r.upperBound.advanced(by: offset)
        }
        let range = Range(countableRange)
        
        return source[range]
    }
    
    fileprivate func enumerateDictionaries(inside node:NSDictionary, usingBlock:(_ item: NSDictionary, _ stop: inout Bool)->())
    {
        if (node[SwiftDocKey.substructure] != nil) {
            let childs = node[SwiftDocKey.substructure] as! Array<NSDictionary>
            for (item) in childs {
                var shouldStop = false
                usingBlock(item, &shouldStop)
                if (shouldStop) {
                    return
                } else {
                    enumerateDictionaries(inside: item, usingBlock: usingBlock)
                }
            }
        }
    }
    
    fileprivate func makeRange(_ fromNode: NSDictionary, parameter: String = "", offset: Int = 0) -> CountableRange<Int>
    {
        let start = fromNode["key.\(parameter)offset"] as! Int - offset
        let end = fromNode["key.\(parameter)length"] as! Int + start
        return start..<end
    }
    
}
