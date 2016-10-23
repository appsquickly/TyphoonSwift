//
//  ActivatedAssembly.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 19/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation

enum ActivatedAssemblyError: Error {
    case circularDependencyWhileInit
}

class ActivatedAssembly
{
    fileprivate var __container: ActivatedAssemblyContainer!
    
    init() {
        __container = ActivatedAssemblyContainer()
    }
    
    func componentForType<ComponentType: Any>() -> ComponentType?
    {
        return __container.componentForType() as ComponentType?
    }
    
    func inject<ComponentType: Any>(_ instance: inout ComponentType)
    {
        __container.inject(&instance)
    }
    
    class func container(_ forAssembly: ActivatedAssembly) -> ActivatedAssemblyContainer {
        return forAssembly.__container
    }
    
    class func activate<AssemblyType: ActivatedAssembly>(_ assembly: AssemblyType) -> AssemblyType {
        self.container(assembly).activate()
        return assembly
    }
}

class ActivatedAssemblyContainer
{
    fileprivate var pools: [Definition.Scope: ComponentsPool] = [:]
    
    //Used to identify when initialization graph complete
    fileprivate var initializationStack = CallStack()
    
    //Used to store configuration block and created instance
    fileprivate var configureStack = CallStack()
    
    //Used to store insatnces while calling configuration blocks (used to solve circular references with prototype scopes)
    fileprivate var instanceStack = CallStack()
    
    fileprivate var registry: [ActivatedDefinition] = []
    
    fileprivate var eagerSingletoneActivations: [() -> ()] = []
    
    init() {
        self.createPools()
    }
    
    /// Activates current assembly.
    func activate()
    {
        activateEagerSingletons()
    }
    
    func registerDefinition<ComponentType: Any>(_ definition: ActivatedGenericDefinition<ComponentType>)
    {
        registry.append(definition)
        
        if definition.scope == Definition.Scope.Singletone {
            eagerSingletoneActivations.append({
                self.component(forDefinition: definition)
            })
        }
    }
    
    func inject<ComponentType: Any>(_ instance: inout ComponentType)
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
        print("Couldn't cast definition for key \(key)")
        return nil
    }
    
    fileprivate func definitionsForType<ComponentType: Any>() -> [ActivatedGenericDefinition<ComponentType>]
    {
        var candidates : [ActivatedGenericDefinition<ComponentType>] = []
        for definition in registry {
            if let definition = definition as? ActivatedGenericDefinition<ComponentType> {
                candidates.append(definition)
            }
        }
        return candidates
    }
    
    fileprivate func definition(forKey key: String) -> ActivatedDefinition?
    {
        for definition in registry {
            if definition.key == key {
                return definition
            }
        }
        return nil
    }
    
    fileprivate func inject<ComponentType: Any>(_ instance: inout ComponentType, withDefinition definition: ActivatedGenericDefinition<ComponentType>)
    {
        storeSharedInstance(instance, withScope: definition.scope, forKey: definition.key)
        
        instanceStack.push(StackElement(withInstance: instance, key: definition.key))
        
        if let configure = definition.configuration {
            configure(&instance)
        }
        
        instanceStack.pop()
        
        if instanceStack.isEmpty() {
            clearObjectGraphPool()
        }
    }
    
    internal func component<ComponentType: Any>(forDefinition definition: ActivatedGenericDefinition<ComponentType>) -> ComponentType
    {
        if let sharedInstance = sharedInstance(withScope: definition.scope, forKey: definition.key) as? ComponentType {
            return sharedInstance
        }
        
        if let stackedInstance = stackedInstance(forKey: definition.key) as? ComponentType {
            return stackedInstance
        }
        
        let element = StackElement(withKey: definition.key)
        
        initializationStack.push(element)
        let instance = definition.initialization!()
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
                    var instanceToConifgure = element.instance as! ComponentType
                    configureBlock(&instanceToConifgure)
                    // Rewrite configured instance into pool (in case of structure)
                    storeSharedInstance(instanceToConifgure, withScope: definition.scope, forKey: definition.key)
                }
            }
            
            instanceStack.pop()
            
            if instanceStack.isEmpty() {
                clearObjectGraphPool()
            }
        }
        
        return instance
    }
    
    fileprivate func stackedInstance(forKey key: String) -> Any?
    {
        // Cannot resolve circular reference inside initialization
        if initializationStack.peek(forKey: key) != nil {
            var keys = initializationStack.keys()
            keys.append(key)
            let stackString = keys.joined(separator: " -> ")
            fatalError("\n\n\nCircular reference in initializers while building component '\(key)'. Stack: \(stackString)\n\n\n")
        }
        
        if let stackedInstance = instanceStack.peek(forKey: key)?.instance {
            return stackedInstance
        }
        
        return nil
    }
    
    fileprivate func sharedInstance(withScope scope: Definition.Scope, forKey key: String) -> Any?
    {
        if let pool = pools[scope] {
            if let cachedInstance = pool.objectForKey(key) {
                return cachedInstance
            }
        }
        return nil
    }
    
    fileprivate func storeSharedInstance(_ instance: Any, withScope scope: Definition.Scope, forKey key: String)
    {
        if let pool = pools[scope] {
            pool.setObject(instance, forKey: key)
        }
    }
    
    fileprivate func clearObjectGraphPool()
    {
        if let pool = pools[Definition.Scope.ObjectGraph] {
            pool.removeAllObjects()
        }
    }
    
    fileprivate func createPools()
    {
        let strongPool = StrongPool()
        pools = [
            Definition.Scope.WeakSingletone : WeakPool(),
            Definition.Scope.ObjectGraph : StrongPool(),
            Definition.Scope.Singletone : strongPool,
            Definition.Scope.LazySingletone : strongPool,
        ]
    }
    
    fileprivate func activateEagerSingletons()
    {
        for activation in eagerSingletoneActivations {
            activation()
        }
        eagerSingletoneActivations = []
    }
}

