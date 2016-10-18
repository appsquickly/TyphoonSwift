//
//  AssemblyGenerator.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 19/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation
import Stencil

struct Replacement {
    var range: CountableRange<Int>! = 0..<0
    var string: String! = ""
}

// TODO: Refactor generators to use one of template enigines..

class FileGenerator
{
    let indentStep = "    "
    
    var file :FileDefinition!
    
    convenience init(file: FileDefinition) {
        self.init()
        self.file = file
    }
    ////////////////////////////////////////
    /// TEMPLATE PARAMs METHODS
    
    
    
    func assemblyDict(fromAssembly assembly: AssemblyDefinition) -> [String: AnyObject] {
        
        var assemblyDict:[String: AnyObject] = [:]
        assemblyDict["name"] = assembly.name as AnyObject
        
        var allMethodDicts: [AnyObject] = []
        for method in assembly.methods {
            let dict = methodDict(fromMethod: method)
            allMethodDicts.append(dict as AnyObject)
        }
        
        assemblyDict["methods"] = allMethodDicts as AnyObject

        return assemblyDict
    }
    
    func methodDict(fromMethod method: MethodDefinition) -> [String: AnyObject] {
        var methodDict:[String: AnyObject] = [:]
        
        methodDict["name"] = method.name as AnyObject
        methodDict["returnType"] = method.returnDefinition!.className! as AnyObject
        methodDict["args"] = method.args as AnyObject?
        
        if let definition = method.definitions.first {
            let dict = definitionDict(fromDefinition: definition)
            methodDict["definition"] = dict as AnyObject
        }
        
        return methodDict
    }
    
    func definitionDict(fromDefinition definition: InstanceDefinition) -> [String: AnyObject] {
        var definitionDict:[String: AnyObject] = [:]
        definitionDict["key"] = definition.key as AnyObject
        definitionDict["scope"] = "Definition.Scope.\(definition.scope)" as AnyObject
        definitionDict["class"] = definition.className as AnyObject
        definitionDict["properties"] = propertyInjections(definition.propertyInjections) as AnyObject
        return definitionDict
    }
    
    func propertyInjections(_ injections: [PropertyInjection]) -> [[String: String]] {
        var properties :[[String: String]] = []
        
        for prop in injections {
            properties.append(["name": prop.propertyName, "value" : prop.injectedValue])
        }
        
        return properties
    }
    
    func registerFilters(withNamespace namespace: Namespace) {
        namespace.registerFilter("uppercaseFirst") { value in
            if let value = value as? String {
                return value.uppercaseFirst
            }
            return value
        }

    }
    
    ////////////////////////////////////////
    
    
    func generate(to outputPath :String)
    {
        var contextDict: [ String: AnyObject ] = [:]
        
        var allAssemblyDicts: [AnyObject] = []
        
        for assembly in file.assemblies {
            let dict = assemblyDict(fromAssembly: assembly)
            allAssemblyDicts.append(dict as AnyObject)
        }
        
        contextDict["assemblies"] = allAssemblyDicts as AnyObject
        
        
        do {
            contextDict["loader"] = TemplateLoader(bundle:[Bundle.main])
            
            let namespace = Namespace()
            registerFilters(withNamespace: namespace)
            
            let context = Context(dictionary: contextDict, namespace: namespace)
            
            
            let template = try Template(named: "Assemblies.stencil")
            
            let rendered = try template.render(context)
            try rendered.write(toFile: outputPath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to render template \(error)")
        }
        
        
        
        return
        
        
        var outputBuffer = ""
     
        outputBuffer += "import Foundation"

        for assembly in file.assemblies {
            outputBuffer += generateAssembly(assembly)
        }
    
        outputBuffer += "\n\n// Extensions\n"
        for assembly in file.assemblies {
            outputBuffer += "\n"
            outputBuffer += generateAssemblyExtension(assembly)
        }
        
        outputBuffer += generateActivation(file.assemblies)
    
        do {
            try outputBuffer.write(toFile: outputPath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed writing to path")
        }
        
    }
    
    func generateActivation(_ assemblies: [AssemblyDefinition]) -> String
    {
        var outputBuffer = ""
        
        outputBuffer += "\n\n// Umbrella activation\n"
        outputBuffer += "extension Typhoon {\n"
        outputBuffer += indentStep + "class func activateAssemblies() {\n"
        for assembly in assemblies {
            outputBuffer += indentStep + indentStep + "\(assembly.name).assembly \n"
        }
        outputBuffer += indentStep + "}\n"
        outputBuffer += "}"
        
        return outputBuffer
    }
    
    func generateAssembly(_ assembly: AssemblyDefinition) -> String
    {
        var outputBuffer = ""
        
        outputBuffer += "\n\nclass \(assemblyImplClassName(assembly)) : ActivatedAssembly { \n"
        
        for method in assembly.methods {
            if method.numberOfRuntimeArguments() == 0 {
                outputBuffer += generateActivatedDefinitionMethod(forMethod: method, indent: indentStep)
            }
        }

        
        for method in assembly.methods {
            outputBuffer += generateMethod(method, indent: indentStep)
        }
        
        outputBuffer += generateDefinitionsRegistrations(assembly.methods, indent: indentStep)

        
        outputBuffer += "}"

        return outputBuffer
    }
    
    func generateActivatedDefinitionMethod(forMethod method: MethodDefinition, indent: String) -> String
    {
        var output = ""
        
        let definition = method.returnDefinition
        
        output += "\n" + indent + "private func definitionFor\(method.name.uppercaseFirst) -> ActivatedGenericDefinition<\(method.returnDefinition!.className!)>\n"
        output += indent + "{\n"
       
        output += generateActivatedDefinition(forDefinition: definition!, indent: indent + indent)
        
        output += indent + indent + "return definition\n"
        output += indent + "}\n"
        
        return output
    }
    
    func generateActivatedDefinition(forDefinition definition: InstanceDefinition, ivarName: String = "definition", indent: String) -> String
    {
        var output = ""
        
        output += indent + "let \(ivarName) = ActivatedGenericDefinition<\(definition.className!)>(withKey: \"\(definition.key)\")\n"
        
        // scope
        let scope = "Definition.Scope.\(definition.scope)"
        output += indent + "\(ivarName).scope = \(scope)\n"
        
        // initialization
        output += indent + "\(ivarName).initialization = {\n"
        output += indent + indentStep + "return \(definition.className!)()\n"
        output += indent + "}\n"
        
        //configuration
        if definition.propertyInjections.count > 0 {
            output += indent + "\(ivarName).configuration = { instance in \n"
            output += generatePropertyInjections(definition.propertyInjections, ivar: "instance", indent: indent + indentStep)
            output += indent  + "}\n"
        }
        
        return output
    }
    
    func generateDefinitionsRegistrations(_ definitions: [MethodDefinition],indent: String) -> String
    {
        var output = "\n"
        
        output += indent + "override init() {\n"
        output += indent + indentStep + "super.init()\n"
        output += indent + indentStep + "registerAllDefinitions()\n"
        output += indent + "}\n"
        
        output += "\n"

        
        output += indent + "private func registerAllDefinitions() {\n"
        for method in definitions {
            if method.numberOfRuntimeArguments() == 0 {
                 output += indent + indentStep + "ActivatedAssembly.container(self).registerDefinition(definitionFor\(method.name.uppercaseFirst))\n"
            }
        }
        output += indent + "}\n"

        return output
    }
    
    func assemblyImplClassName(_ assembly: AssemblyDefinition) ->String
    {
        return "\(assembly.name as String)Implementation"
    }
    
    func generateAssemblyExtension(_ assembly: AssemblyDefinition) -> String
    {
        var outputBuffer = ""
        
        outputBuffer += "extension \(assembly.name) {\n"
        outputBuffer += indentStep + "class var assembly :\(assemblyImplClassName(assembly)) {\n"
        outputBuffer += indentStep + indentStep + "get {\n"
        outputBuffer += indentStep + indentStep + indentStep + "struct Static {\n"
        outputBuffer += indentStep + indentStep + indentStep + "static var onceToken: dispatch_once_t = 0\n"
        outputBuffer += indentStep + indentStep + indentStep + "static var instance: \(assemblyImplClassName(assembly))? = nil\n"
        outputBuffer += indentStep + indentStep + "}\n"
        outputBuffer += indentStep + indentStep + "dispatch_once(&Static.onceToken) {\n"
        outputBuffer += indentStep + indentStep + indentStep + "Static.instance = \(assemblyImplClassName(assembly))()\n"
        outputBuffer += indentStep + indentStep + indentStep + "ActivatedAssembly.container(Static.instance!).activate()\n"
        outputBuffer += indentStep + indentStep + "}\n"
        outputBuffer += indentStep + indentStep + "return Static.instance!\n"
        outputBuffer += indentStep + indentStep + "}\n"
        outputBuffer += indentStep + "}\n"
        outputBuffer += "}\n"
        
        return outputBuffer
    }
    
    func generateMethod(_ method: MethodDefinition, indent: String) -> String
    {
        var outputBuffer = ""
        
        outputBuffer += "\n\(indent)func \(method.name) -> \(method.returnDefinition!.className!) { "
        
        let insideIndent = indent + indentStep
        
        outputBuffer += "\n"
        
        if method.numberOfRuntimeArguments() > 0 {
            outputBuffer += generateActivatedDefinition(forDefinition: method.returnDefinition!, indent: insideIndent)
            outputBuffer += insideIndent + "return ActivatedAssembly.container(self).component(forDefinition: definition)"
        } else {
            outputBuffer += insideIndent + "return ActivatedAssembly.container(self).component(forKey: \"\(method.returnDefinition!.key)\") as \(method.returnDefinition!.className!)!"
        }
        
//        outputBuffer += generateInstance(method.returnDefinition, indent: insideIndent)
        
        outputBuffer += "\n"
        
        outputBuffer += "\(indent)}\n"
        
        return outputBuffer
    }
    
    func trimEmptyLines(_ string: inout String)
    {
        var lines: [String] = []
        string.enumerateLines { line, _ in lines.append(line) }
        
        
        string = lines.filter{!$0.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty}.joined(separator: "\n")
    }

    
    func generatePropertyInjections(_ injections: [PropertyInjection], ivar: String, indent: String) -> String
    {
        var outputBuffer = ""
        for injection in injections {
            outputBuffer += "\(indent)\(generatePropertyInjection(injection, ivar: ivar))\n"
        }
        return outputBuffer
    }
    
    func generatePropertyInjection(_ injection: PropertyInjection, ivar: String) -> String
    {
        return "\(ivar).\(injection.propertyName) = \(injection.injectedValue)"
    }
    
    fileprivate func replace(inside buffer: inout String, replacements: [Replacement]) {
        let replaceBuffer = replacements.sorted { a, b in
            return a.range.lowerBound > b.range.lowerBound
        }
        for replacement in replaceBuffer {
            let startIndex = buffer.characters.index(buffer.startIndex, offsetBy: replacement.range.lowerBound)
            let endIndex = buffer.characters.index(buffer.startIndex, offsetBy: replacement.range.upperBound)
            
            let indexRange = startIndex..<endIndex
            
            buffer.replaceSubrange(indexRange, with: replacement.string)
        }
        
    }
}
