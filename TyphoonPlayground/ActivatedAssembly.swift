//
//  ActivatedAssembly.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 19/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation

class ActivatedAssembly
{
    func component<ComponentType: AnyObject>( @autoclosure initialization: () -> ComponentType, key: String, scope: Definition.Scope = Definition.Scope.Prototype, configure: ((ComponentType) -> ())? = nil ) -> ComponentType {
        
        let instance = initialization()
        
        if let configure = configure {
            configure(instance)
        }
        
        return instance
    }
    
    init() {
        self.activateEagerSingletons()
    }
    
    func activateEagerSingletons()
    {
        for (method) in singletones() {
            method()
        }
    }
    
    func singletones() -> [()->(AnyObject)]
    {
        return []
    }

}