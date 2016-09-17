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
        
        static func fromString(_ string: String) -> Scope? {
            return Scope(rawValue: (string as NSString).pathExtension)
        }
    }

    fileprivate var _scope : Scope = .Prototype;
    
    func setScope(_ scope: Scope) {
        _scope = scope
    }
    
    func scope() -> Scope {
        return _scope
    }

    convenience init(withClass:Any, configuration:((Definition)->())? = nil) {
        self.init()
    }
    
    
    func injectProperty(_ property:String, with:Any) {
        
    }
    
}
