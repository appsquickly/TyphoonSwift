//
//  AssemblyGenerator.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 19/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation
import Stencil
import PathKit

class FileGenerator
{
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
        methodDict["returnType"] = method.returnDefinition!.className as AnyObject
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
        definitionDict["methods"] = methodInjections(definition.methodInjections) as AnyObject
        if let initializer = definition.initializer {
            definitionDict["initializer"] = methodCall(initializer) as AnyObject
        } else {
            definitionDict["initializer"] = "\(definition.className)()" as AnyObject
        }
        definitionDict["configuration"] = (definition.methodInjections.count > 0 || definition.propertyInjections.count > 0) as AnyObject
        
        return definitionDict
    }
    
    func propertyInjections(_ injections: [PropertyInjection]) -> [[String: String]] {
        var properties :[[String: String]] = []
        
        for prop in injections {
            properties.append(["name": prop.propertyName, "value" : prop.injectedValue])
        }
        
        return properties
    }
    
    func methodInjections(_ injections: [MethodInjection]) -> [String] {
        
        var methodInjections: [String] = []
        
        for method in injections {
            methodInjections.append(methodCall(method))
        }
        
        return methodInjections
    }
    
    func methodCall(_ method: MethodInjection) -> String {
        
        if method.arguments.count > 0 {
            
            method.arguments.sort(by: { (arg1, arg2) -> Bool in
                return arg1.injectedIndex < arg2.injectedIndex
            })
            
            var call = method.methodSelector
            
            let paramsCount = method.methodSelector.numberOfSelectorParams()
            
            method.methodSelector.enumerateParams() { param, index in
                
                var replacement: String = ""
                if param == "_:" {
                    replacement = method.arguments[index].injectedValue
                } else {
                    replacement = "\(param) \(method.arguments[index].injectedValue)"
                }
                
                let isLast = (index == paramsCount - 1)
                if !isLast {
                    replacement = "\(replacement), "
                }
                
                call = call.stringByReplacingFirstOccurrenceOfString(target: param, withString: replacement)
            }
            
            return "\(call)"
        } else {
            return "\(method.methodSelector)()"
        }
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
            let templateLoader = TemplateLoader(paths: [Path("\(ResourceDir)/Templates/")])
            
            contextDict["loader"] = templateLoader
            
            let namespace = Namespace()
            registerFilters(withNamespace: namespace)
            
            let context = Context(dictionary: contextDict, namespace: namespace)
            
            
            let template = templateLoader.loadTemplate("Assemblies.stencil")!
            
            let rendered = try template.render(context)
            try rendered.write(toFile: outputPath, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            print("Failed to render template \(error)")
        }
    }
    
}
