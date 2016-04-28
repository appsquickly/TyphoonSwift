//
//  ActivatedAssembly.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 19/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation

enum ActivatedAssemblyError: ErrorType {
    case CircularDependencyWhileInit
}

class ActivatedAssembly
{
    private var pools: [Definition.Scope: ComponentsPool] = [:]
    
    private var stack = CallStack()
    
    //Used to identify when initialization graph complete
    private var initializationStack = CallStack()
    
    //Used to store configuration block and created instance
    private var configureStack = CallStack()
    
    //Used to store insatnces while calling configuration blocks (used to solve circular references with prototype scopes)
    private var instanceStack = CallStack()
    
//    private var  = CallStack()
    
    internal func component<ComponentType: Any>( @autoclosure initialization: () -> ComponentType, key: String, scope: Definition.Scope = Definition.Scope.Prototype, configure: ((inout ComponentType) -> ())? = nil ) -> ComponentType
    {
        if let sharedInstance = sharedInstance(withScope: scope, forKey: key) as? ComponentType {
            return sharedInstance
        }
        
        if let stackedInstance = stackedInstance(forKey: key) as? ComponentType {
            return stackedInstance
        }
        
        let element = StackElement(withKey: key)
        
        initializationStack.push(element)
        let instance = initialization()
        initializationStack.pop()
        
        
        let configureElement = StackElement(withKey: key)
        configureElement.instance = instance
        
        
        if let configure = configure {
            configureElement.configuration = configure
            configureStack.push(configureElement)
        }
        
        storeSharedInstance(instance, withScope: scope, forKey: key)
        
        if initializationStack.isEmpty() {
            
            instanceStack.push(StackElement(withInstance: instance, key: key))
            
            //Copy and clear configuration stack
            let configures = configureStack.copy()
            configureStack.clear()
            
            //Run all configuration blocks
            for element in configures.elements {
                
                //Run configuration block
                if let configureBlock = element.configuration as? (inout ComponentType) -> () {
                    var configureInstance = element.instance as! ComponentType
                    configureBlock(&configureInstance)
                }
            }
            
            instanceStack.pop()
            
            if instanceStack.isEmpty() {
                clearObjectGraphPool()
            }
        }
        
        return instance
    }
    
    internal func singletones() -> [()->(Any)]
    {
        return []
    }
    
    init() {
        self.createPools()
        self.activateEagerSingletons()
    }
    
    private func stackedInstance(forKey key: String) -> Any?
    {
        // Cannot resolve circular reference inside initialization
        if initializationStack.peek(forKey: key) != nil {
            var keys = initializationStack.keys()
            keys.append(key)
            let stackString = keys.joinWithSeparator(" -> ")
            fatalError("\n\n\nCircular reference in initializers while building component '\(key)'. Stack: \(stackString)\n\n\n")
        }
        
        if let stackedInstance = instanceStack.peek(forKey: key)?.instance {
            return stackedInstance
        }
        
        return nil
    }
    
    private func sharedInstance(withScope scope: Definition.Scope, forKey key: String) -> Any?
    {
        if let pool = pools[scope] {
            if let cachedInstance = pool.objectForKey(key) {
                return cachedInstance
            }
        }
        return nil
    }
    
    private func storeSharedInstance(instance: Any, withScope scope: Definition.Scope, forKey key: String)
    {
        if let pool = pools[scope] {
            pool.setObject(instance, forKey: key)
        }
    }
    
    private func clearObjectGraphPool()
    {
        if let pool = pools[Definition.Scope.ObjectGraph] {
            pool.removeAllObjects()
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