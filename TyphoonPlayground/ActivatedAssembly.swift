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
    
    //Used to identify when initialization graph complete
    private var initializationStack = CallStack()
    
    //Used to store configuration block and created instance
    private var configureStack = CallStack()
    
    //Used to store insatnces while calling configuration blocks (used to solve circular references with prototype scopes)
    private var instanceStack = CallStack()
    
    private var registry: [ActivatedDefinition] = []
    
    func registerDefinition(definition: ActivatedDefinition)
    {
        registry.append(definition)
    }
    
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
    
    func inject<ComponentType: Any>(inout instance: ComponentType)
    {
        let candidates: [ActivatedGenericDefinition<ComponentType>] = definitionsForType()
        if candidates.count == 1 {
            let definition = candidates.first!
            inject(&instance, withDefinition: definition)
        } else if candidates.count > 1 {
            print("Typhoon Warning: Found more than one candidate for specified type \(ComponentType.self)")
        }
    }
    
    func componentForType<ComponentType: Any>() -> ComponentType?
    {
        let candidates: [ActivatedGenericDefinition<ComponentType>] = definitionsForType()
        if candidates.count == 1 {
            return component(forDefinition: candidates.first!)
        } else if candidates.count > 1 {
            print("Typhoon Warning: Found more than one candidate for specified type \(ComponentType.self)")
        }
        return nil
    }
    
    func allComponentForType<ComponentType: Any>() -> [ComponentType]
    {
        let candidates: [ActivatedGenericDefinition<ComponentType>] = definitionsForType()
        var instances: [ComponentType] = []
        for definition in candidates {
            instances.append(component(forDefinition: definition))
        }
        return instances
    }
    
    func component<ComponentType: Any>(forKey key: String) -> ComponentType?
    {
        if let definition = definition(forKey: key) as? ActivatedGenericDefinition<ComponentType> {
            return component(forDefinition: definition)
        }
        return nil
    }
    
    private func definitionsForType<ComponentType: Any>() -> [ActivatedGenericDefinition<ComponentType>]
    {
        var candidates : [ActivatedGenericDefinition<ComponentType>] = []
        for definition in registry {
            if let definition = definition as? ActivatedGenericDefinition<ComponentType> {
                candidates.append(definition)
            }
        }
        return candidates
    }
    
    private func definition(forKey key: String) -> ActivatedDefinition?
    {
        for definition in registry {
            if definition.key == key {
                return definition
            }
        }
        return nil
    }
    
    private func inject<ComponentType: Any>(inout instance: ComponentType, withDefinition definition: ActivatedGenericDefinition<ComponentType>)
    {
        storeSharedInstance(instance, withScope: definition.scope, forKey: definition.key)
        
        instanceStack.push(StackElement(withInstance: instance, key: definition.key))
        
        if let configure = definition.configuration {
            configure(&instance, nil)
        }
        
        instanceStack.pop()
        
        if instanceStack.isEmpty() {
            clearObjectGraphPool()
        }
    }
    
    private func component<ComponentType: Any>(forDefinition definition: ActivatedGenericDefinition<ComponentType>, args: RuntimeArguments? = nil) -> ComponentType
    {
        if let sharedInstance = sharedInstance(withScope: definition.scope, forKey: definition.key) as? ComponentType {
            return sharedInstance
        }
        
        if let stackedInstance = stackedInstance(forKey: definition.key) as? ComponentType {
            return stackedInstance
        }
        
        let element = StackElement(withKey: definition.key)
        
        initializationStack.push(element)
        let instance = definition.initialization!(args)
        initializationStack.pop()
        
        
        let configureElement = StackElement(withKey: definition.key)
        configureElement.instance = instance
        
        
        if let configure = definition.configuration {
            configureElement.configuration = configure
            configureStack.push(configureElement)
        }
        
        storeSharedInstance(instance, withScope: definition.scope, forKey: definition.key)
        
        if initializationStack.isEmpty() {
            
            instanceStack.push(StackElement(withInstance: instance, key: definition.key))
            
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
    
    internal func registerAllDefinitions()
    {
    
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
//        for (method) in singletones() {
//            method()
//        }
    }
}