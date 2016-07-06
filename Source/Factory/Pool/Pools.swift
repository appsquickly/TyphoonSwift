//
//  Pools.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 26/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation

private protocol InstanceContainer : class {
    associatedtype InstanceType
    var instance: InstanceType? { get }
}

private class StrongContainer<C> : InstanceContainer {
    var strongInstance: C?
    
    var instance: C? {
        return strongInstance
    }
    
    init(instance: C) {
        strongInstance = instance
    }
}

private class WeakContainer<C: AnyObject> : InstanceContainer {
    weak var weakInstance: C?
    
    var instance: C? {
        return weakInstance
    }
    
    init(instance: C) {
        weakInstance = instance
    }
}


protocol ComponentsPool {
    
    func setObject(anObject: Any, forKey aKey: String)
    
    func objectForKey(aKey: String) -> Any?
    
    var allValues: [Any] { get }
    
    func removeAllObjects()
}

class StrongPool : ComponentsPool
{
    private var dictionary :[String: StrongContainer<Any>] = [:]
    
    func setObject(anObject: Any, forKey aKey: String)
    {
        dictionary[aKey] = StrongContainer(instance: anObject)
    }
    
    func objectForKey(aKey: String) -> Any?
    {
        return dictionary[aKey]?.instance
    }

    var allValues: [Any] {
        get {
            var array :[Any] = []
            for value in dictionary.values {
                if let instance = value.instance {
                    array.append(instance)
                }
            }
            return array
        }
    }
    
    func removeAllObjects()
    {
        dictionary.removeAll()
    }
    
}

class WeakPool : ComponentsPool
{
    private var dictionary :[String: WeakContainer<AnyObject>] = [:]
    
    func setObject(anObject: Any, forKey aKey: String)
    {
        if let object = anObject as? AnyObject {
            dictionary[aKey] = WeakContainer(instance: object)
        } else {
            fatalError("Cannot use weak singletone scopes with structures, since structures are not referemces")
        }
    }
    
    func objectForKey(aKey: String) -> Any?
    {
        return dictionary[aKey]?.instance
    }
    
    var allValues: [Any] {
        get {
            var array :[Any] = []
            for value in dictionary.values {
                if let instance = value.instance {
                    array.append(instance)
                }
            }
            return array
        }
    }
    
    func removeAllObjects()
    {
        dictionary.removeAll()
    }
    
}
