//
//  main.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 15/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation


let inputPath = "/Users/alex/Development/TyphoonPlayground/TyphoonPlayground/input.swift"
let outputPath = "/Users/alex/Development/TyphoonPlayground/TyphoonPlayground/output.swift"

let fileDefinitionBuilder = FileDefinitionBuilder(filePath: inputPath)
if let file = fileDefinitionBuilder.build() {
    let generator = FileGenerator(file: file)
    generator.generate(to: outputPath)
}

Typhoon.activateAssemblies()


//CoreComponents.assembly.

//let controller = CoreComponents.assembly.shareService2()
//
//let controller2 = CoreComponents.assembly.shareService2()
//
//let man = CoreComponents.assembly.man()
//print("man: \(man.name)")
//
//if man === man.brother!.brother! {
//    print("Hey bro!")
//}
//
//

extension CoreComponentsImplementation
{
    
    func definitionForRootController() -> ActivatedGenericDefinition<String>
    {
        let definition = ActivatedGenericDefinition<String>(withKey: "rootController")
        definition.initialization = { args in
            return "Hello world"
        }
        definition.configuration = { instance, args in
            instance.appendContentsOf("123")
        }
        definition.scope = Definition.Scope.Prototype
        return definition
    }
//
    private func definitionForFirstViewController() -> ActivatedGenericDefinition<Int>
    {
        let definition = ActivatedGenericDefinition<Int>(withKey: "int")
        definition.initialization = { args in
            return 1
        }
        definition.scope = Definition.Scope.Prototype
        return definition
    }
    
    func firstViewController() -> Int
    {
        return component(forKey: "int") as Int!
    }
    
//
    func registerAllDefinitions2() {
        
//        self.registerDefinition(definitionForRootController())
//        self.registerDefinition(definitionForFirstViewController())

        
        if let result = self.component(forKey: "rootController") as String? {
            print("Result: \(result)")
        }
        
        if let value1 = self.componentForType() as Int? {
            print("Int: \(value1)")
        }
        
        if let value2 = self.componentForType() as String? {
            print("String: \(value2)")
        }
        
//        let definition2 = definitionForFirstViewController()
//        
//        let res = self.component(forDefinition: definition2)
    
//        self.registerDefinition(definition as ActivatedDefinition<Any> )
        
    }
}


let args = RuntimeArguments(withArguments: [])

args.arguments = ["", 1, ActivatedGenericDefinition<Int>(withKey: "int"), { return "hello" }]

if let str = args.arguments[0] as? String {
    print("String!")
}

if let str = args.arguments[1] as? Int {
    print("Int!")
}

if let str = args.arguments[2] as? ActivatedGenericDefinition<Int> {
    print("ActivatedGenericDefinition<int>!")
}

if let str = args.arguments[3] as? () -> (String) {
    print("block")
}


//let component = CoreComponents.assembly.component1()
//
//
////CoreComponents.assembly
//
//if let backRef = component.dependency?.dependency?.dependency  {
//    if backRef === component {
//        print("Matches!")
//    } else {
//        print("\(backRef) != \(component)")
//    }
//} else {
//    print("Can't get gependency")
//}
//
CoreComponents.assembly.registerAllDefinitions2()

//print("bro: \(man == man.brother!.brother!)")


//print("Controller1: \(controller)")
//print("Controller2: \(controller)")
//
//class Home {
//    // Autoinjections
//    var owner = CoreComponents.assembly.rootController()
//}

//let home = Home()


//print("Owner Name: \(home.owner.name)")