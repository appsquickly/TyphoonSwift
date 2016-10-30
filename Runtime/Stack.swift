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


class CallStack
{    
    var elements: [StackElement] = []
    
    func push(_ element: StackElement)
    {
        elements.append(element)
    }
    
    func pop() -> StackElement?
    {
        return elements.popLast()
    }
    
    func peek(forKey key: String) -> StackElement?
    {
        for element in elements.reversed() {
            if element.key == key {
                return element
            }
        }
        return nil
    }
    
    func isResolving(key:String) -> Bool
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
