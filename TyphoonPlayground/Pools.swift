//
//  Pools.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 26/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation

protocol ComponentsPool {
    
    func setObject(anObject: AnyObject, forKey aKey: NSCopying)
    
    func objectForKey(aKey: AnyObject) -> AnyObject?
    
    var allValues: [AnyObject] { get }
    
    func removeAllObjects()
}

class StrongPool : ComponentsPool
{
    var dictionary = NSMutableDictionary()
    
    func setObject(anObject: AnyObject, forKey aKey: NSCopying)
    {
        dictionary.setObject(anObject, forKey: aKey)
    }
    
    func objectForKey(aKey: AnyObject) -> AnyObject?
    {
        return dictionary.objectForKey(aKey)
    }
    
    var allValues: [AnyObject] {
        get {
            return dictionary.allValues
        }
    }
    
    func removeAllObjects()
    {
        dictionary.removeAllObjects()
    }
    
}

class WeakPool : ComponentsPool {
    
    var weakTable = NSMapTable.strongToWeakObjectsMapTable()
    
    func setObject(anObject: AnyObject, forKey aKey: NSCopying)
    {
        weakTable.setObject(anObject, forKey: aKey)
    }
    
    func objectForKey(aKey: AnyObject) -> AnyObject?
    {
        return weakTable.objectForKey(aKey)
    }
    
    var allValues: [AnyObject] {
        get {
            if let allObjects = weakTable.objectEnumerator()?.allObjects {
                return allObjects
            }
            return []
        }
    }
    
    func removeAllObjects()
    {
        weakTable.removeAllObjects()
    }
    
}