//
//  FileDefinitionBuilder.swift
//  TyphoonPackage
//
//  Created by Igor Vasilenko on 21/09/2016.
//
//

import Foundation

class FileDefinitionBuilder {
    
    var fileName :String!
    var filePath :String!
    
    convenience init(filePath: String)
    {
        self.init()
        self.fileName = (filePath as NSString).lastPathComponent
        self.filePath = filePath
    }
    
    func build() -> FileDefinition?
    {
        if let (text, json) = loadFile() {
            let file = FileDefinition(fileName: fileName)
            file.assemblies = buildAssemblies(from: text, withJson: json)
            return file
        }
        
        return nil
    }
    
    func buildAssemblies(from text: String, withJson json: NSDictionary) -> [AssemblyDefinition]
    {
        var assemblies: [AssemblyDefinition] = []
        
        if let substructure = json["key.substructure"] as? [NSDictionary] {
            for item in substructure {
                if item["key.kind"] as! String == SourceLang.Declaration.class {
                    if let types = item["key.inheritedtypes"] as? [NSDictionary] {
                        for type in types {
                            if type["key.name"] as! String == "Assembly" {
                                
                                let assemblyBuilder = AssemblyDefinitionBuilder(node: item, text: text)
                                
                                if let assemblyDefinition = assemblyBuilder.build() {
                                    assemblies.append(assemblyDefinition)
                                }
                                break
                            }
                        }
                    }
                }
            }
        }
        
        return assemblies
    }
    
    func loadFile() -> (String, NSDictionary)?
    {
        var text :String, json :NSDictionary
        
        do {
            text = try NSString.init(contentsOfFile: self.filePath, encoding: String.Encoding.utf8.rawValue) as String
            let parsedString = Terminal.bash("/usr/local/bin/sourcekitten", arguments: ["structure", "--text", text])
            json = jsonFromString(parsedString) as NSDictionary!
        } catch {
            return nil
        }
        
        return (text, json)
    }
    
    func jsonFromString(_ string: String) -> NSDictionary?
    {
        var json: NSDictionary
        do {
            let data = string.data(using: String.Encoding.utf8) as Data!
            json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions()) as! NSDictionary
        } catch {
            return nil
        }
        return json
    }
}
