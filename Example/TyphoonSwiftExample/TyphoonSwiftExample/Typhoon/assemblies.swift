import Foundation


class ViewsFactoryImplementation : ActivatedAssembly {

    override init() {
        super.init()
        registerAllDefinitions()
    }
    
    

    private func registerAllDefinitions() {
    }
}


class CoreComponentsImplementation : ActivatedAssembly {

    override init() {
        super.init()
        registerAllDefinitions()
    }
    
    
    
    private func definitionForManWithInitializer() -> ActivatedGenericDefinition<Man>
    {
        let definition = ActivatedGenericDefinition<Man>(withKey: "manWithInitializer")
        definition.scope = Definition.Scope.Prototype
        definition.initialization = {
            return Man(withName: "Tom")
        }
        definition.configuration = { instance in
        
            instance.setAdultAge()
            instance.setValues("John", withAge: 21)
        }

        return definition
    }
    
    
    private func definitionForManWithMethods() -> ActivatedGenericDefinition<Man>
    {
        let definition = ActivatedGenericDefinition<Man>(withKey: "manWithMethods")
        definition.scope = Definition.Scope.Prototype
        definition.initialization = {
            return Man()
        }
        definition.configuration = { instance in
        
            instance.setPet(pet: "Barsik")
            instance.setCompany("Loud&Clear")
        }

        return definition
    }
    
    
    private func definitionForRootController() -> ActivatedGenericDefinition<Woman>
    {
        let definition = ActivatedGenericDefinition<Woman>(withKey: "rootController")
        definition.scope = Definition.Scope.Prototype
        definition.initialization = {
            return Woman()
        }
        definition.configuration = { instance in
            instance.age = 23
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
    
    
    private func definitionForComponent1() -> ActivatedGenericDefinition<Component>
    {
        let definition = ActivatedGenericDefinition<Component>(withKey: "component1")
        definition.scope = Definition.Scope.Prototype
        definition.initialization = {
            return Component()
        }
        definition.configuration = { instance in
            instance.dependency = self.component2()
        
        }

        return definition
    }
    
    
    private func definitionForComponent2() -> ActivatedGenericDefinition<Component>
    {
        let definition = ActivatedGenericDefinition<Component>(withKey: "component2")
        definition.scope = Definition.Scope.Prototype
        definition.initialization = {
            return Component()
        }
        definition.configuration = { instance in
            instance.dependency = self.component3()
        
        }

        return definition
    }
    
    
    private func definitionForComponent3() -> ActivatedGenericDefinition<Component>
    {
        let definition = ActivatedGenericDefinition<Component>(withKey: "component3")
        definition.scope = Definition.Scope.Prototype
        definition.initialization = {
            return Component()
        }
        definition.configuration = { instance in
            instance.dependency = self.component1()
        
        }

        return definition
    }
    
    

    func manWith(_ name: String) -> Man { 
        let definition = ActivatedGenericDefinition<Man>(withKey: "manWith:")
        definition.scope = Definition.Scope.ObjectGraph
        definition.initialization = {
            return Man()
        }
        definition.configuration = { instance in
            instance.name = name
            instance.brother = self.man()
        
        }
		return ActivatedAssembly.container(self).component(forDefinition: definition)
    }
    
    func manWithInitializer() -> Man { 
        return ActivatedAssembly.container(self).component(forKey: "manWithInitializer") as Man!
    }
    
    func manWithMethods() -> Man { 
        return ActivatedAssembly.container(self).component(forKey: "manWithMethods") as Man!
    }
    
    func rootController() -> Woman { 
        return ActivatedAssembly.container(self).component(forKey: "rootController") as Woman!
    }
    
    func shareService2() -> Service { 
        return ActivatedAssembly.container(self).component(forKey: "shareService2") as Service!
    }
    
    func shareService(_ withArgument:Int) -> Service { 
        let definition = ActivatedGenericDefinition<Service>(withKey: "shareService:")
        definition.scope = Definition.Scope.WeakSingletone
        definition.initialization = {
            return Service()
        }
		return ActivatedAssembly.container(self).component(forDefinition: definition)
    }
    
    func man() -> Man { 
        return ActivatedAssembly.container(self).component(forKey: "man") as Man!
    }
    
    func name() -> String { 
        return ActivatedAssembly.container(self).component(forKey: "name") as String!
    }
    
    func component1() -> Component { 
        return ActivatedAssembly.container(self).component(forKey: "component1") as Component!
    }
    
    func component2() -> Component { 
        return ActivatedAssembly.container(self).component(forKey: "component2") as Component!
    }
    
    func component3() -> Component { 
        return ActivatedAssembly.container(self).component(forKey: "component3") as Component!
    }
    
    private func registerAllDefinitions() {
        ActivatedAssembly.container(self).registerDefinition(definitionForManWithInitializer())
        ActivatedAssembly.container(self).registerDefinition(definitionForManWithMethods())
        ActivatedAssembly.container(self).registerDefinition(definitionForRootController())
        ActivatedAssembly.container(self).registerDefinition(definitionForShareService2())
        ActivatedAssembly.container(self).registerDefinition(definitionForMan())
        ActivatedAssembly.container(self).registerDefinition(definitionForName())
        ActivatedAssembly.container(self).registerDefinition(definitionForComponent1())
        ActivatedAssembly.container(self).registerDefinition(definitionForComponent2())
        ActivatedAssembly.container(self).registerDefinition(definitionForComponent3())
    }
}



// Assembly accessors

extension ViewsFactory {
	class var assembly: ViewsFactoryImplementation {
		get {
			struct Static {
				static let instance = ActivatedAssembly.activate(ViewsFactoryImplementation())
			}
			return Static.instance
		}
	}
}

extension CoreComponents {
	class var assembly: CoreComponentsImplementation {
		get {
			struct Static {
				static let instance = ActivatedAssembly.activate(CoreComponentsImplementation())
			}
			return Static.instance
		}
	}
}


// Umbrella activation
extension Typhoon {
    class func activateAssemblies() { 
        _ = ViewsFactory.assembly
        _ = CoreComponents.assembly
    }
}
