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

class AssemblyDefinitionBuilder {
    
    var node: NSDictionary!
    var text: String!
    
    convenience init(node: NSDictionary, text: String) {
        self.init()
        self.node = node
        self.text = text
    }
    
    func build() -> AssemblyDefinition?
    {
        if let assemblyName = node["key.name"] as? String {
            
            let assembly = AssemblyDefinition(withName: assemblyName)
            
            if let substructure = node["key.substructure"] as? [NSDictionary] {
                for item in substructure {
                    if item["key.kind"] as! String == SourceLang.Declaration.instanceMethod {
                        
                        let methodBuilder = MethodDefinitionBuilder(source: text, node: item)
                        
                        if let methodDefinition = methodBuilder.build() {
                            assembly.methods.append(methodDefinition)
                        }
                    }
                }
            }
            return assembly
        }
        return nil
    }
    
}
