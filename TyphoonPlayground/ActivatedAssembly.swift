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
    private var pools: [Definition.Scope: ComponentsPool] = [:]
    
    internal func component<ComponentType: AnyObject>( @autoclosure initialization: () -> ComponentType, key: String, scope: Definition.Scope = Definition.Scope.Prototype, configure: ((ComponentType) -> ())? = nil ) -> ComponentType
    {
        if let sharedInstance = sharedInstance(withScope: scope, forKey: key) as? ComponentType {
            return sharedInstance
        }
        
        let instance = initialization()
        
        storeSharedInstance(instance, withScope: scope, forKey: key)
        
        if let configure = configure {
            configure(instance)
        }
        
        return instance
    }
    
    internal func singletones() -> [()->(AnyObject)]
    {
        return []
    }
    
    init() {
        self.createPools()
        self.activateEagerSingletons()
    }
    
    private func sharedInstance(withScope scope: Definition.Scope, forKey key: String) -> AnyObject?
    {
        if let pool = pools[scope] {
            if let cachedInstance = pool.objectForKey(key) {
                return cachedInstance
            }
        }
        return nil
    }
    
    private func storeSharedInstance(instance: AnyObject, withScope scope: Definition.Scope, forKey key: String)
    {
        if let pool = pools[scope] {
            pool.setObject(instance, forKey: key)
        }
    }
    
    private func createPools()
    {
        let strongPool = StrongPool()
        pools = [
            Definition.Scope.WeakSingletone : WeakPool(),
            Definition.Scope.ObjectGraph : StrongPool(),
            Definition.Scope.Singletone : strongPool,
            Definition.Scope.LazySingletone : strongPool,
        ]
    
    }
    
    private func activateEagerSingletons()
    {
        for (method) in singletones() {
            method()
        }
    }
}