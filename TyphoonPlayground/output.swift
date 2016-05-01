import Foundation

class ViewsFactoryImplementation : ActivatedAssembly { 

    override func registerAllDefinitions() {
        super.registerAllDefinitions()
    }}

class CoreComponentsImplementation : ActivatedAssembly { 

    private func definitionForRootController() -> ActivatedGenericDefinition<Woman>
    {
        let definition = ActivatedGenericDefinition<Woman>(withKey: "rootController")
        definition.scope = Definition.Scope.Prototype
        definition.initialization = {
            return Woman()
        }
        definition.configuration = { instance in 
            instance.age = 22
            instance.name = "Anna"
        }
        return definition
    }

    private func definitionForShareService2() -> ActivatedGenericDefinition<Service>
    {
        let definition = ActivatedGenericDefinition<Service>(withKey: "shareService2")
        definition.scope = Definition.Scope.Singletone
        definition.initialization = {
            return Service()
        }
        definition.configuration = { instance in 
            instance.name = "Hello world"
        }
        return definition
    }

    private func definitionForMan() -> ActivatedGenericDefinition<Man>
    {
        let definition = ActivatedGenericDefinition<Man>(withKey: "man")
        definition.scope = Definition.Scope.Prototype
        definition.initialization = {
            return Man()
        }
        definition.configuration = { instance in 
            instance.name = "Vit"
            instance.brother = self.manWith("Alex")
        }
        return definition
    }

    private func definitionForName() -> ActivatedGenericDefinition<String>
    {
        let definition = ActivatedGenericDefinition<String>(withKey: "name")
        definition.scope = Definition.Scope.Prototype
        definition.initialization = {
            return String()
        }
        return definition
    }

    func manWith(name: String) -> Man { 
        let definition = ActivatedGenericDefinition<Man>(withKey: "manWith:")
        definition.scope = Definition.Scope.ObjectGraph
        definition.initialization = {
            return Man()
        }
        definition.configuration = { instance in 
            instance.name = name
            instance.brother = self.man()
        }
        return component(forDefinition: definition)
    }

    func rootController() -> Woman { 
        return component(forKey: "rootController") as Woman!
    }

    func shareService2() -> Service { 
        return component(forKey: "shareService2") as Service!
    }

    func shareService(withArgument:Int) -> Service { 
        let definition = ActivatedGenericDefinition<Service>(withKey: "shareService:")
        definition.scope = Definition.Scope.WeakSingletone
        definition.initialization = {
            return Service()
        }
        return component(forDefinition: definition)
    }

    func man() -> Man { 
        return component(forKey: "man") as Man!
    }

    func name() -> String { 
        return component(forKey: "name") as String!
    }

    override func registerAllDefinitions() {
        super.registerAllDefinitions()
        registerDefinition(definitionForRootController())
        registerDefinition(definitionForShareService2())
        registerDefinition(definitionForMan())
        registerDefinition(definitionForName())
    }}

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