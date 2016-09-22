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

class FileDefinitionBuilder {
    
    var fileName: String!
    var filePath: URL!
    
    convenience init(filePath: String) {
        self.init()
        self.filePath = URL(fileURLWithPath: filePath)
        self.fileName = self.filePath.lastPathComponent
    }
    
    func build() -> FileDefinition? {
        let fileStructure = FileStructure(filePathURL: self.filePath)
        if let (text, json) = fileStructure.structure {
            let file = FileDefinition(fileName: fileName)
            file.assemblies = buildAssemblies(from: text, withJson: json)
            return file
        }
        
        return nil
    }
    
    func buildAssemblies(from text: String, withJson json: JSON) -> [AssemblyDefinition] {
        var assemblies: [AssemblyDefinition] = []
        
        if let substructure = json[SwiftDocKey.substructure].array {
            let assemblyTypeItems = assemblyTypeItemsInStructure(structure: substructure)
            for item in assemblyTypeItems {
                /// TODO: Fix initialization after AssemblyDefinitionBuilder refactoring
                let assemblyBuilder = AssemblyDefinitionBuilder(node: NSDictionary(), text: text)
                if let assemblyDefinition = assemblyBuilder.build() {
                    assemblies.append(assemblyDefinition)
                }
            }
        }
        
        return assemblies
    }
    
    fileprivate func assemblyTypeItemsInStructure(structure: [JSON]) -> [JSON] {
        var items: [JSON] = []
        for item in structure {
            if item[SwiftDocKey.kind].string == SourceLang.Declaration.class {
                if let types = item[SwiftDocKey.inheritedTypes].array {
                    for type in types {
                        if type[SwiftDocKey.name] == "Assembly" {
                            items.append(item)
                        }
                    }
                }
            }
        }
        return items
    }
}
