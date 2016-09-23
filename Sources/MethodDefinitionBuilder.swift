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
    var node: JSON!
    
    var methodBody: String!
    
    internal lazy var definitionRegexp: NSRegularExpression = {
        return NSRegularExpression(pattern: "->\\s*?(Definition)\\s*?\\{")!
    }()
    
    convenience init(source: String, node: JSON) {
        self.init()
        self.source = source
        self.node = node
        
        self.methodBody = content(from: self.node[SwiftDocKey.bodyOffset], length: self.node[SwiftDocKey.bodyLength]) as String!
    }
    
    func build() -> MethodDefinition? {
        
        guard isTyphoonDefinition() else {
            return nil
        }
        
        let name = content(from: self.node[SwiftDocKey.nameOffset], length: self.node[SwiftDocKey.nameLength]) as String!
        let methodOffset = self.node[SwiftDocKey.bodyOffset].integer!
        
        let methodDefinition = MethodDefinition(name: name!, originalSource: self.methodBody)
        parseArgumentsForMethod(methodDefinition)
        
        let key = keyFromMethodName(self.node[SwiftDocKey.name].string!)
        
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
    
    func parseArgumentsForMethod(_ method: MethodDefinition)
    {
        if method.numberOfRuntimeArguments() > 0 {
            
            let name = method.name!.replacingOccurrences(of: "\n", with: "")
            let content = NSRegularExpression.matchedGroup(pattern: "\\((.*)\\)", insideString: name) as String!
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
    
    func instanceDefinition(fromCall call: JSON, methodOffset: Int, key: String) -> (InstanceDefinition, Bool)
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
    
    func getDefinitionConfigurationFromCall(_ call: JSON, methodOffset: Int, contentHandler: ([JSON], String, Bool) -> ()) -> Bool
    {
        if let configuration = configurationBlock(call, offset: methodOffset) {
            contentHandler(configuration.content, configuration.firstArgumentName, false)
        }
        
        var isResult = false
        
        let callOffset = call[SwiftDocKey.offset].integer! - methodOffset
        
        if let ivarName = ivarAssignment(beforeLocation: callOffset) {
            
            isResult = isReturn(withIvar: ivarName)
            
            if let content = self.node[SwiftDocKey.substructure].array {
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
    
    func configurationBlock(_ fromCall: JSON, offset: Int) -> BlockNode?
    {
        do {
            return try blockFromCall(fromCall, argumentName: "configuration", offset: offset)
        } catch {
            print("Error while getting configuration block")
            return nil
        }
    }
    
    func propertyInjectionsFromBlock(_ block: BlockNode, methodOffset: Int) -> [PropertyInjection]
    {
        let blockOffset = block.range.first!
        
        print("Trying to get properties for \(block.firstArgumentName)")
        
        return propertyInjectionsFromContent(block.content, ivar: block.firstArgumentName, contentOffset: methodOffset + blockOffset)
    }
    
    func scopeFromContent(_ contents: [JSON], ivar: String) -> Definition.Scope?
    {
        var scope : Definition.Scope? = nil
        
        for item in contents {
            if let name = item[SwiftDocKey.name].string {
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
    
    func propertyInjectionsFromContent(_ content: [JSON], ivar: String, contentOffset: Int) -> [PropertyInjection]
    {
        var injections :[PropertyInjection] = []
        
        for item in content {
            if let name = item[SwiftDocKey.name].string {
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
    
    func propertyInjectionFromParameter(_ parameter: JSON, offset: Int) -> PropertyInjection
    {
        let params = parameter[SwiftDocKey.substructure].array!
        
        let propertyRawName = content(from: params[0][SwiftDocKey.bodyOffset], length: params[0][SwiftDocKey.bodyLength]) as String!
        let propertyName = propertyRawName?.replacingOccurrences(of: "\"", with: "")
        
        let injectedValue = content(from: params[1][SwiftDocKey.bodyOffset], length: params[1][SwiftDocKey.bodyLength]) as String!
        
        let injection = PropertyInjection(propertyName: propertyName!, injectedValue: injectedValue!)
        injection.range = makeRange(parameter, offset: offset)
        
        return injection
    }
    
    func blockFromCall(_ fromCall: JSON, argumentIndex: ArgumentIndex = ArgumentIndex.last, argumentName: String, offset: Int) throws -> BlockNode?
    {
        if let blockParameter = parameterFromCall(fromCall, atIndex: argumentIndex) {
            
            if !isBlockParameter(blockParameter, parameterName:  argumentName) {
                return nil
            }
            
            let block = BlockNode()
            
            if isMultilineBlockParameter(blockParameter) {
                let header = blockParameter[SwiftDocKey.substructure].array!
                for item in header {
                    let kind = item[SwiftDocKey.kind].string!
                    switch kind {
                    case SourceLang.Declaration.varParameter:
                        if let name = item[SwiftDocKey.name].string {
                            block.argumentNames.append(name)
                        }
                    case SourceLang.Statement.brace:
                        if let blockContent = item[SwiftDocKey.substructure].array {
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
                var substructure = blockParameter[SwiftDocKey.substructure].array!
                for (index, item) in substructure.enumerated() {
                    switch item[SwiftDocKey.kind].string! {
                    case SourceLang.Declaration.varParameter:
                        if let name = item[SwiftDocKey.name].string {
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
    
    func parameterFromCall(_ call: JSON, atIndex: ArgumentIndex) -> JSON?
    {
        var argumentIndex :Int = 0
        let array = call[SwiftDocKey.substructure].array!
        
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
    func findCalls(_ caller: String, methodName :String...) -> [JSON]?
    {
        var array = [JSON]()
        findCalls(self.node, toArray: &array, caller: caller, methodNames: methodName)
        return array
    }
    
    func findCalls(_ insideDictionary: JSON, toArray: inout [JSON], caller: String, methodNames: [String])
    {
        enumerateDictionaries(inside: insideDictionary) { (item, shouldStop) in
            if (item[SwiftDocKey.kind] != nil && item[SwiftDocKey.kind].string! == SourceLang.Expr.call) {
                if (item[SwiftDocKey.name].string! == caller && self.isCallNode(item, matchesParamNames: methodNames)) {
                    toArray.append(item)
                }
            }
        }
    }
    
    func parameterWithName(_ name: String, fromCall call:JSON) -> JSON?
    {
        if (call[SwiftDocKey.substructure] != nil) {
            for item in call[SwiftDocKey.substructure].array! {
                if item[SwiftDocKey.kind].string == SourceLang.Declaration.varParameter {
                    if (item[SwiftDocKey.name].string == name) {
                        return item
                    }
                }
            }
        }
        return nil
    }
    
    func typeFromDefinitionCall(_ callNode: JSON) -> String
    {
        if let classParam = parameterWithName("withClass", fromCall: callNode) {
            
            let rawType = content(from: classParam[SwiftDocKey.bodyOffset], length: classParam[SwiftDocKey.bodyLength])!
            
            return rawType.replacingOccurrences(of: ".self", with: "")
        } else {
            return ""
        }
    }
    
    //# MARK: - Internal functions
    
    internal func keyFromMethodName(_ name: String) -> String {
        return name.replacingOccurrences(of: "[_\\(\\)]", with: "", options: NSString.CompareOptions.regularExpression, range: nil)
    }
    
    internal func content(from startLocation: Any?, length: Any?) -> String? {
        let start = startLocation as! Int
        let end = (length as! Int) + start
        
        return source[start..<end]
    }
    
    internal func content(_ r: CountableRange<Int>, offset: Int = 0) -> String? {
        var countableRange = r
        if (offset > 0) {
            countableRange = r.lowerBound.advanced(by: offset)..<r.upperBound.advanced(by: offset)
        }
        let range = Range(countableRange)
        
        return source[range]
    }
    
    private func enumerateDictionaries(inside node:JSON, usingBlock:(_ item: JSON, _ stop: inout Bool)->()) {
        if (node[SwiftDocKey.substructure] != nil) {
            let childs = node[SwiftDocKey.substructure].array!
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
    
    internal func makeRange(_ fromNode: JSON, parameter: String = "", offset: Int = 0) -> CountableRange<Int> {
        let start = fromNode["key.\(parameter)offset"].integer! - offset
        let end = fromNode["key.\(parameter)length"].integer! + start
        return start..<end
    }
    
}
