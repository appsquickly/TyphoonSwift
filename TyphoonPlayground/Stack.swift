//
//  Stack.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 26/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation


class CallStack
{    
    var elements: [StackElement] = []
    
    func push(element: StackElement)
    {
        elements.append(element)
    }
    
    func pop() -> StackElement?
    {
        return elements.popLast()
    }
    
    func peek(forKey key: String) -> StackElement?
    {
        for element in elements.reverse() {
            if element.key == key {
                return element
            }
        }
        return nil
    }
    
    func isResolving(key key:String) -> Bool
    {
        return peek(forKey: key) != nil
    }
    
    func isEmpty() -> Bool
    {
        return elements.isEmpty
    }
    
    func copy() -> CallStack
    {
        let copy = CallStack()
        copy.elements = self.elements
        return copy
    }
    
    func clear()
    {
        self.elements = []
    }
    
    func keys() -> [String]
    {
        var keys : [String] = []
        for element in self.elements {
            keys.append(element.key)
        }
        return keys
    }
}


class StackElement
{
    var key: String!
    
    var instance: Any?
    var configuration: Any?
    
    init(withKey key:String) {
        self.key = key
    }
    
    init(withInstance: Any, key: String) {
        self.instance = withInstance
        self.key = key
    }
}