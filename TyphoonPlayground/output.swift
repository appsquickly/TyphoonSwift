import Foundation

class ViewsFactoryImplementation : ActivatedAssembly { 

    override func singletones() -> [()->(AnyObject)]
    {
        return []
    }
}

class CoreComponentsImplementation : ActivatedAssembly { 

    func manWith(name: String) -> Man { 
        return component(Man(), key: "manWith:", scope: Definition.Scope.ObjectGraph, configure: { instance in 
            instance.name = name
        })
    }

    func rootController() -> Woman { 
        return component(Woman(), key: "rootController", scope: Definition.Scope.Prototype, configure: { instance in 
            instance.age = 22
            instance.name = "Anna"
        })
    }

    func shareService2() -> Service { 
        return component(Service(), key: "shareService2", scope: Definition.Scope.Singletone, configure: { instance in 
            instance.name = "Hello world"
        })
    }

    func shareService(withArgument:Int) -> Service { 
        return component(Service(), key: "shareService:", scope: Definition.Scope.WeakSingletone)
    }

    override func singletones() -> [()->(AnyObject)]
    {
        return [shareService2]
    }
}

// Extensions

extension ViewsFactory {
    class var assembly :ViewsFactoryImplementation {
        get {
            struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: ViewsFactoryImplementation? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = ViewsFactoryImplementation()
        }
        return Static.instance!
        }
    }
}

extension CoreComponents {
    class var assembly :CoreComponentsImplementation {
        get {
            struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: CoreComponentsImplementation? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = CoreComponentsImplementation()
        }
        return Static.instance!
        }
    }
}


// Umbrella activation
extension Typhoon {
    class func activateAssemblies() {
        ViewsFactory.assembly 
        CoreComponents.assembly 
    }
}