//
//  MethodDefinition.swift
//  TyphoonPackage
//
//  Created by Igor Vasilenko on 23/09/2016.
//
//

import Foundation

class MethodDefinition {
    
    struct Argument : CustomStringConvertible {
        var attributes: [String] = []
        var label: String?
        var ivar: String = ""
        var type: String = ""
        var defaultValue: String?
        
        var description: String {
            get {
                return "\(attributes.joined(separator: " ")) \(label ?? "") \(ivar):\(type)\(defaultValue != nil ? " = \(defaultValue!)": "")"
            }
        }
        
    }
    
    var args : [Argument] = []
    var name : String
    var source : String
    var definitions: [InstanceDefinition]! = []
    
    weak var returnDefinition: InstanceDefinition?
    
    init(name: String, originalSource: String) {
        self.name = name
        self.source = originalSource
        self.parseArguments()
    }
    
    func numberOfRuntimeArguments() -> Int {
        var count = 0
        for character in name.characters {
            if character == ":" {
                count += 1
            }
        }
        return count
    }
    
    func addDefinition(_ definition: InstanceDefinition) {
        self.definitions.append(definition)
    }
}

extension MethodDefinition {
    
    func parseArguments() {
        if self.numberOfRuntimeArguments() > 0 {
            let name = self.name.replacingOccurrences(of: "\n", with: "")
            let content = NSRegularExpression.matchedGroup(pattern: "\\((.*)\\)", insideString: name) as String!
            let argStrings = content?.components(separatedBy: ",")
            
            var arguments: [Argument] = []
            
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
            }
            
            self.args = arguments
        }
    }
}
