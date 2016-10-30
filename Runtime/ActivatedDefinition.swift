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


class ActivatedDefinition
{
    var scope: Definition.Scope = Definition.Scope.ObjectGraph
    
    var key: String!
    
    init(withKey: String)
    {
        self.key = withKey
    }
    
}

class ActivatedGenericDefinition<ComponentType> : ActivatedDefinition
{
    var initialization: (() -> (ComponentType))?
    var configuration: ((inout ComponentType) -> ())? = nil
    
    override init(withKey: String)
    {
        super.init(withKey: withKey)
    }
}
