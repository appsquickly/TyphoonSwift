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
    
    func setObject(_ anObject: Any, forKey aKey: String)
    
    func objectForKey(_ aKey: String) -> Any?
    
    var allValues: [Any] { get }
    
    func removeAllObjects()
}

class StrongPool : ComponentsPool
{
    fileprivate var dictionary :[String: StrongContainer<Any>] = [:]
    
    func setObject(_ anObject: Any, forKey aKey: String)
    {
        dictionary[aKey] = StrongContainer(instance: anObject)
    }
    
    func objectForKey(_ aKey: String) -> Any?
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
    fileprivate var dictionary :[String: WeakContainer<AnyObject>] = [:]
    
    func setObject(_ anObject: Any, forKey aKey: String)
    {
        if let object = anObject as AnyObject? {
            dictionary[aKey] = WeakContainer(instance: object)
        } else {
            fatalError("Cannot use weak singletone scopes with structures, since structures are not referenced")
        }
    }
    
    func objectForKey(_ aKey: String) -> Any?
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
