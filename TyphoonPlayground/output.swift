import Foundation

class ViewsFactoryImplementation : ActivatedAssembly { 

    override func singletones() -> [()->(Any)]
    {
        return []
    }
}

class CoreComponentsImplementation : ActivatedAssembly { 

    private func definitionForManWith(name: String) -> ActivatedGenericDefinition<Man>
    {
        let definition = ActivatedGenericDefinition<Man>(withKey: "manWith:")
        definition.scope = Definition.Scope.ObjectGraph
        return definition
    }

    func manWith(name: String) -> Man { 
        return component(Man(), key: "manWith:", scope: Definition.Scope.ObjectGraph, configure: { instance in 
            instance.name = name
            instance.brother = self.man()
        })
    }

    private func definitionForRootController() -> ActivatedGenericDefinition<Woman>
    {
        let definition = ActivatedGenericDefinition<Woman>(withKey: "rootController")
        definition.scope = Definition.Scope.Prototype
        return definition
    }

    func rootController() -> Woman { 
        return component(Woman(), key: "rootController", scope: Definition.Scope.Prototype, configure: { instance in 
            instance.age = 22
            instance.name = "Anna"
        })
    }

    private func definitionForShareService2() -> ActivatedGenericDefinition<Service>
    {
        let definition = ActivatedGenericDefinition<Service>(withKey: "shareService2")
        definition.scope = Definition.Scope.Singletone
        return definition
    }

    func shareService2() -> Service { 
        return component(Service(), key: "shareService2", scope: Definition.Scope.Singletone, configure: { instance in 
            instance.name = "Hello world"
        })
    }

    private func definitionForShareService(withArgument:Int) -> ActivatedGenericDefinition<Service>
    {
        let definition = ActivatedGenericDefinition<Service>(withKey: "shareService:")
        definition.scope = Definition.Scope.WeakSingletone
        return definition
    }

    func shareService(withArgument:Int) -> Service { 
        return component(Service(), key: "shareService:", scope: Definition.Scope.WeakSingletone)
    }

    private func definitionForMan() -> ActivatedGenericDefinition<Man>
    {
        let definition = ActivatedGenericDefinition<Man>(withKey: "man")
        definition.scope = Definition.Scope.Prototype
        return definition
    }

    func man() -> Man { 
        return component(Man(), key: "man", scope: Definition.Scope.Prototype, configure: { instance in 
            instance.name = "Vit"
            instance.brother = self.manWith("Alex")
        })
    }

    private func definitionForName() -> ActivatedGenericDefinition<String>
    {
        let definition = ActivatedGenericDefinition<String>(withKey: "name")
        definition.scope = Definition.Scope.Prototype
        return definition
    }

    func name() -> String { 
        return component(String(), key: "name", scope: Definition.Scope.Prototype)
    }

    private func definitionForArg1(name: String) -> ActivatedGenericDefinition<Man>
    {
        let definition = ActivatedGenericDefinition<Man>(withKey: "arg1:")
        definition.scope = Definition.Scope.Prototype
        return definition
    }

    func arg1(name: String) -> Man { 
        return component(Man(), key: "arg1:", scope: Definition.Scope.Prototype)
    }

    private func definitionForArg2(name: String, name2: String,name3:String  , name5   :String) -> ActivatedGenericDefinition<Man>
    {
        let definition = ActivatedGenericDefinition<Man>(withKey: "arg2:name2:name3:name5:")
        definition.scope = Definition.Scope.Prototype
        return definition
    }

    func arg2(name: String, name2: String,name3:String  , name5   :String) -> Man { 
        return component(Man(), key: "arg2:name2:name3:name5:", scope: Definition.Scope.Prototype)
    }

    private func definitionForArg3(wname name:String,
                    name3 name2: String) -> ActivatedGenericDefinition<Man>
    {
        let definition = ActivatedGenericDefinition<Man>(withKey: "arg3wname:name3:")
        definition.scope = Definition.Scope.Prototype
        return definition
    }

    func arg3(wname name:String,
                    name3 name2: String) -> Man { 
        return component(Man(), key: "arg3wname:name3:", scope: Definition.Scope.Prototype)
    }

    private func definitionForArg4(wname name: String, _ name2: String) -> ActivatedGenericDefinition<Man>
    {
        let definition = ActivatedGenericDefinition<Man>(withKey: "arg4wname::")
        definition.scope = Definition.Scope.Prototype
        return definition
    }

    func arg4(wname name: String, _ name2: String) -> Man { 
        return component(Man(), key: "arg4wname::", scope: Definition.Scope.Prototype)
    }

    private func definitionForArg5(inout wname name: String, _ name2: String? = "213") -> ActivatedGenericDefinition<Man>
    {
        let definition = ActivatedGenericDefinition<Man>(withKey: "arg5wname::")
        definition.scope = Definition.Scope.Prototype
        return definition
    }

    func arg5(inout wname name: String, _ name2: String? = "213") -> Man { 
        return component(Man(), key: "arg5wname::", scope: Definition.Scope.Prototype)
    }

    private func definitionForArg6(inout name: String, _ name2: String? = "213") -> ActivatedGenericDefinition<Man>
    {
        let definition = ActivatedGenericDefinition<Man>(withKey: "arg6::")
        definition.scope = Definition.Scope.Prototype
        return definition
    }

    func arg6(inout name: String, _ name2: String? = "213") -> Man { 
        return component(Man(), key: "arg6::", scope: Definition.Scope.Prototype)
    }

    override func singletones() -> [()->(Any)]
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