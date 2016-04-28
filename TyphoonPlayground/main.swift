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
//    generator.generate(to: outputPath)
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
let component = CoreComponents.assembly.component1()

if let backRef = component.dependency?.dependency?.dependency  {
    if backRef === component {
        print("Matches!")
    } else {
        print("\(backRef) != \(component)")
    }
} else {
    print("Can't get gependency")
}

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