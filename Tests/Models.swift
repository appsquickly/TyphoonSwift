//
//  GeneratorModels.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 23/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation


protocol Injection {
    var external: Bool { get }
}

class FileDefinition : CustomStringConvertible {
    var assemblies: [AssemblyDefinition]!
    var fileName: String!
    
    convenience init(fileName: String)
    {
        self.init()
        self.fileName = fileName
        self.assemblies = []
    }
    
    var description: String {
        get {
            return "FileDefinition( '\(self.fileName)',  assemblies(\(self.assemblies)) )"
        }
    }
}

class AssemblyDefinition : CustomStringConvertible {
    var name: String!
    var methods: [MethodDefinition]!
    
    convenience init(withName name: String)
    {
        self.init()
        self.name = name
        self.methods = []
    }
    
    var description: String {
        get {
            return "AssemblyDefinition( '\(self.name)',  methods(\(self.methods)) )"
        }
    }
}

class PropertyInjection : Injection, CustomStringConvertible, Hashable {
    var propertyName : String!
    var injectedValue : String!
    
    var range: Range<Int>?
    
    var external: Bool = false
    
    convenience init(propertyName: String, injectedValue: String) {
        self.init()
        self.propertyName = propertyName
        self.injectedValue = injectedValue
    }
    
    var description: String {
        get {
            return "PropertyInjection( '\(self.propertyName)' with '\(self.injectedValue)' )"
        }
    }
    
    var hashValue: Int {
        get {
            return propertyName.hashValue
        }
    }
}

func == (lhs: PropertyInjection, rhs: PropertyInjection) -> Bool {
    return lhs.propertyName == rhs.propertyName
}

class InstanceDefinition {
    
    var key : String! = ""

    var className : String?
    var scope = Definition.Scope.Prototype
    
    var range: Range<Int>?
    
    var propertyInjections : [PropertyInjection] = []
    
    func add(propertyInjection: PropertyInjection) {
        for (index, injection) in propertyInjections.enumerate() {
            if injection.propertyName == propertyInjection.propertyName {
                propertyInjections.removeAtIndex(index)
                break
            }
        }
        propertyInjections.append(propertyInjection)
    }
    
    func add(propertyInjections: [PropertyInjection])
    {
        for injection in propertyInjections {
            add(injection)
        }
    }
}

class MethodDefinition {
    
    struct Argument : CustomStringConvertible{
        var attributes: [String] = []
        var label: String?
        var ivar: String = ""
        var type: String = ""
        var defaultValue: String?
        
        var description: String {
            get {
                
                return "\(attributes.joinWithSeparator(" ")) \(label ?? "") \(ivar):\(type)\(defaultValue != nil ? " = \(defaultValue!)": "")"
            }
        }
        
    }
    
    var args : [Argument] = []
    
    var name : String!
    var source : String!
    
    var definitions: [InstanceDefinition]! = []
    
    weak var returnDefinition: InstanceDefinition!
    
    convenience init(name: String, originalSource: String) {
        self.init()
        self.name = name
        self.source = originalSource
    }
    
    func numberOfRuntimeArguments() -> Int
    {
        var count = 0
        for character in name.characters {
            if character == ":" {
                count += 1
            }
        }
        return count
    }
    
    func addDefinition(definition: InstanceDefinition) {
        self.definitions.append(definition)
    }
    
}

enum ArgumentIndex {
    case Index(Int)
    case Last
}

class BlockNode {
    var argumentNames :[String] = []
    var content :[NSDictionary] = []
    
    var source: String! = ""
    var range: Range<Int>! = 0..<0
    
    var firstArgumentName :String
    {
        get {
            var definitionName = "$0"
            if self.argumentNames.count > 0 {
                definitionName = self.argumentNames[0]
            }
            return definitionName
        }
    }
}

