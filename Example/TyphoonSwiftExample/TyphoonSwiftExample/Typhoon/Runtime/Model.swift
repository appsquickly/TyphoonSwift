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

class Typhoon {
    
}

class Assembly {
    
}

class Method {
    
    func injectArgument(_ argument:Any) {
        
    }
    
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
    
    func useInitializer(_ selector:String, with:((Method)->())? = nil) {
        
    }
    
    func injectMethod(_ selector:String, with:((Method)->())? = nil) {
        
    }
    
}
