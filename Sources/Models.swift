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
    
    init(fileName: String)
    {
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
    var name: String
    var methods: [MethodDefinition]!
    
    init(withName name: String)
    {
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
    var propertyName : String
    var injectedValue : String
    
    var range: CountableRange<Int>?
    
    var external: Bool = false
    
    init(propertyName: String, injectedValue: String) {
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
    
    var key : String = ""

    var className : String?
    var scope = Definition.Scope.Prototype
    
    var range: CountableRange<Int>?
    
    var propertyInjections : [PropertyInjection] = []
    
    func add(_ propertyInjection: PropertyInjection) {
        for (index, injection) in propertyInjections.enumerated() {
            if injection.propertyName == propertyInjection.propertyName {
                propertyInjections.remove(at: index)
                break
            }
        }
        propertyInjections.append(propertyInjection)
    }
    
    func add(_ propertyInjections: [PropertyInjection])
    {
        for injection in propertyInjections {
            add(injection)
        }
    }
}

enum ArgumentIndex {
    case index(Int)
    case last
}

class BlockNode {
    var argumentNames :[String] = []
    var content :[JSON] = []
    
    var source: String! = ""
    var range: CountableRange<Int>! = 0..<0
    
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
