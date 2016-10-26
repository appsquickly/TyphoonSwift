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
    
    var source: String
    var node: JSON
    
    var methodBody: String
    
    internal lazy var definitionRegexp: NSRegularExpression? = {
        var regexp: NSRegularExpression?
        do {
            regexp = try NSRegularExpression(pattern: "->\\s*?(Definition)\\s*?\\{")
        } catch {}
        return regexp
    }()
    
    init(source: String, node: JSON) {
        self.methodBody = ""
        self.source = source
        self.node = node
        self.methodBody = self.content(from: node[SwiftDocKey.bodyOffset].integer!, length: node[SwiftDocKey.bodyLength].integer!) as String!
        
    }
    
    func build() -> MethodDefinition? {
        
        guard isTyphoonDefinition() else {
            return nil
        }
        
        let name = content(from: self.node[SwiftDocKey.nameOffset].integer!, length: self.node[SwiftDocKey.nameLength].integer!) as String!
        let methodOffset = self.node[SwiftDocKey.bodyOffset].integer!
        
        let methodDefinition = MethodDefinition(name: name!, originalSource: self.methodBody)
        
        let key = keyFromMethodName(self.node[SwiftDocKey.name].string!)
        
        if let definitionCalls = findCalls("Definition", methodName: "withClass") {
            for call in definitionCalls {
                let (definition, isResult) = instanceDefinition(fromCall: call, methodOffset: methodOffset, key: key)
                methodDefinition.addDefinition(definition)
                if isResult {
                    methodDefinition.returnDefinition = definition
                }
            }
            assert(methodDefinition.returnDefinition != nil)
        }
        
        
        return methodDefinition
    }
    
    func instanceDefinition(fromCall call: JSON, methodOffset: Int, key: String) -> (InstanceDefinition, Bool)
    {
        let definition = InstanceDefinition()
        definition.className = typeFromDefinitionCall(call)
        definition.range = makeRange(call, offset: methodOffset)
        definition.key = key
        
        let isResult = getDefinitionConfigurationFromCall(call, methodOffset: methodOffset) { content, ivarName, isExternal in
            
            definition.initializer = initializerInjectionsFromContent(content, ivar: ivarName, contentOffset: methodOffset, className: definition.className)
            definition.methodInjections = methodInjectionsFromContent(content, ivar: ivarName, contentOffset: methodOffset)
            
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
    
    func initializerInjectionsFromContent(_ nodes: [JSON], ivar: String, contentOffset: Int, className: String) -> MethodInjection?
    {
        var initializer: MethodInjection? = nil
        
        enumerateItemsFromContent(nodes, withName: "\(ivar).useInitializer") { item in
            assert(initializer == nil, "Only one initializer allowed per definition.")
            initializer = methodInjectionFromItem(item, contentOffset: contentOffset)
            initializer!.methodSelector = initializer!.methodSelector.stringByReplacingFirstOccurrenceOfString(target: "init", withString: className)
        }
        
        return initializer
    }
    
    func methodInjectionsFromContent(_ content: [JSON], ivar: String, contentOffset: Int) -> [MethodInjection]
    {
        var injections: [MethodInjection] = []
        
        enumerateItemsFromContent(content, withName: "\(ivar).injectMethod") { item in
            let method = methodInjectionFromItem(item, contentOffset: contentOffset)
            injections.append(method)
        }
        
        return injections
    }
    
    func methodInjectionFromItem(_ item: JSON, contentOffset: Int) -> MethodInjection
    {
        let selectorParameter = parameterFromCall(item, atIndex: ArgumentIndex.index(0))
        let selectorRange = makeRange(selectorParameter as JSON!, parameter: "body", offset: contentOffset)
        
        var selector = content(selectorRange, offset: contentOffset)!
        selector = selector.replacingOccurrences(of: "\"", with: "")
        
        print("selector: \(selector)")
        let result = MethodInjection(methodSelector: selector)
        
        do {
            if let block = try blockFromCall(item, argumentName: "with", offset: contentOffset) {
                result.arguments = methodArgumentsFromContent(block.content, ivar: block.firstArgumentName, contentOffset: contentOffset)
            } else {
                print("No config block specified")
            }
        }
        catch {
            print("Can't get method injection block with error: \(error)")
        }
        

        return result
    }
    
    func methodArgumentsFromContent(_ content: [JSON], ivar: String, contentOffset: Int) -> [MethodInjection.Argument]
    {
        var arguments: [MethodInjection.Argument] = []
        var index: Int = 0
        
        enumerateItemsFromContent(content, withName: "\(ivar).injectArgument") { item in
            let argument = argumentInjectionFromParameter(item, offset: contentOffset)
            argument.injectedIndex = index
            arguments.append(argument)
            index += 1
        }
        
        return arguments
    }
    
    func propertyInjectionsFromContent(_ content: [JSON], ivar: String, contentOffset: Int) -> [PropertyInjection]
    {
        var injections :[PropertyInjection] = []
        
        enumerateItemsFromContent(content, withName: "\(ivar).injectProperty") { item in
            let property = propertyInjectionFromParameter(item, offset: contentOffset)
            injections.append(property)
        }
        
        return injections
    }
    
    func enumerateItemsFromContent(_ content: [JSON], withName targetName: String, block: (JSON) -> ())
    {
        for item in content {
            if let name = item[SwiftDocKey.name].string {
                switch name {
                case targetName:
                    block(item)
                default: break
                }
            }
        }
    }
    
    func propertyInjectionFromParameter(_ parameter: JSON, offset: Int) -> PropertyInjection
    {
        let params = parameter[SwiftDocKey.substructure].array!
        
        let propertyRawName = content(from: params[0][SwiftDocKey.bodyOffset].integer, length: params[0][SwiftDocKey.bodyLength].integer) as String!
        let propertyName = propertyRawName?.replacingOccurrences(of: "\"", with: "")
        
        let injectedValue = content(from: params[1][SwiftDocKey.bodyOffset].integer, length: params[1][SwiftDocKey.bodyLength].integer) as String!
        
        let injection = PropertyInjection(propertyName: propertyName!, injectedValue: injectedValue!)
        injection.range = makeRange(parameter, offset: offset)
        
        return injection
    }
    
    func argumentInjectionFromParameter(_ parameter: JSON, offset: Int) -> MethodInjection.Argument
    {
        let injection = MethodInjection.Argument()
        injection.injectedValue = content(from: parameter[SwiftDocKey.bodyOffset].integer, length: parameter[SwiftDocKey.bodyLength].integer) as String!
        
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
        
        if let substructure = call[SwiftDocKey.substructure].array {
            switch atIndex {
            case .index(let index):
                argumentIndex = index
            case .last:
                argumentIndex = substructure.count - 1
            }
            
            if argumentIndex > substructure.count - 1 || argumentIndex < 0 {
                return nil
            } else {
                return substructure[argumentIndex]
            }
        } else {
            switch atIndex {
            case .index(let index):
                assert(index == 0, "Found non-zero index for call without substructure")
            default:
                break;
            }
            return call
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
            if (item[SwiftDocKey.kind] != nil && item[SwiftDocKey.kind].string == SourceLang.Expr.call) {
                if (item[SwiftDocKey.name].string == caller && self.isCallNode(item, matchesParamNames: methodNames)) {
                    toArray.append(item)
                }
            }
        }
    }
    
    func parameterWithName(_ name: String, fromCall call:JSON) -> JSON?
    {
        if let substructure = call[SwiftDocKey.substructure].array {
            for item in substructure {
                if item[SwiftDocKey.kind].string == SourceLang.Declaration.argument {
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
            
            let rawType = content(from: classParam[SwiftDocKey.bodyOffset].integer, length: classParam[SwiftDocKey.bodyLength].integer)!
            
            return rawType.replacingOccurrences(of: ".self", with: "")
        } else {
            return ""
        }
    }
    
    //# MARK: - Internal functions
    
    internal func keyFromMethodName(_ name: String) -> String {
        return name.replacingOccurrences(of: "[_\\(\\)]", with: "", options: NSString.CompareOptions.regularExpression, range: nil)
    }
    
    internal func content(from startLocation: Int?, length: Int?) -> String? {
        let start : Int = startLocation as Int!
        let end = (length as Int!) + start
        
        return self.source[start..<end]
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
        if let childs = node[SwiftDocKey.substructure].array {
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
