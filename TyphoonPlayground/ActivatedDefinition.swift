//
//  ActivatedDefinition.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 28/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation


class ActivatedDefinition
{
    var scope: Definition.Scope = Definition.Scope.ObjectGraph
    
    var key: String!
    
    init(withKey: String)
    {
        self.key = withKey
    }
    
}

class RuntimeArguments {
    
    var arguments :[Any] = []
    
    init(withArguments: [Any]) {
        self.arguments = withArguments
    }
    
}

class ActivatedGenericDefinition<ComponentType> : ActivatedDefinition
{
    var initialization: ((RuntimeArguments?) -> (ComponentType))?
    var configuration: ((inout ComponentType, RuntimeArguments?) -> ())? = nil
    
    override init(withKey: String)
    {
        super.init(withKey: withKey)
    }
}