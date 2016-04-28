//
//  Model.swift
//  TyphoonPlayground
//
//  Created by Aleksey Garbarev on 15/04/16.
//  Copyright © 2016 Aleksey Garbarev. All rights reserved.
//

import Foundation

class Typhoon {
    
}

class Assembly {
    
}

class Definition {
    
    enum Scope : String {
        case Prototype
        case ObjectGraph
        case Singletone
        case LazySingletone
        case WeakSingletone
        
        static func fromString(string: String) -> Scope? {
            return Scope(rawValue: (string as NSString).pathExtension)
        }
    }

    private var _scope : Scope = .Prototype;
    
    func setScope(scope: Scope) {
        _scope = scope
    }
    
    func scope() -> Scope {
        return _scope
    }

    convenience init(withClass:Any, configuration:((Definition)->())? = nil) {
        self.init()
    }
    
    
    func injectProperty(property:String, with:Any) {
        
    }
    
}