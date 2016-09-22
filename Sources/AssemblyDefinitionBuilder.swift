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
    
    var node: JSON!
    var text: String!
    
    convenience init(node: JSON, text: String) {
        self.init()
        self.node = node
        self.text = text
    }
    
    func build() -> AssemblyDefinition?
    {
        if let assemblyName = node[SwiftDocKey.name].string {
            
            let assembly = AssemblyDefinition(withName: assemblyName)
            
            if let substructure = node[SwiftDocKey.substructure].array {
                for item in substructure {
                    if item[SwiftDocKey.kind].string == SourceLang.Declaration.instanceMethod {
                        
                        /// TODO: Fix initialization after MethodDefinitionBuilder refactor
                        let methodBuilder = MethodDefinitionBuilder(source: text, node: NSDictionary())
                        
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
