//
//  Assembly.swift


import Foundation

class Man {
    var name :String?;
    var age :UInt?;
    
    var brother: Man?
}

class Woman : Man {
    
}

struct Service {
    var name: String?
    
    init() {
        print("Service created!!")
    }
    
}

class Component {
    
    var dependency :Component?
    
    init() {
        
    }
    
    init(withDependency: Component) {
        self.dependency = withDependency
    }
}

class ViewsFactory : Assembly
{
    
}

class CoreComponents : Assembly {

    var relatedAssembly: ViewsFactory?
    
    func manWith(name: String) -> Definition {
        return Definition(withClass: Man.self) {
            $0.injectProperty("name", with: name)
            $0.setScope(Definition.Scope.ObjectGraph)
            $0.injectProperty("brother", with: self.man())
        }
    }
    
    func rootController() -> Definition {        
        let definitnion = Definition(withClass:Woman.self, configuration: { (d) -> (Void) in
            d.injectProperty("name", with: "Aleksey")
            d.injectProperty("age", with: 22)
        })
        definitnion.injectProperty("name", with: "Anna")
        return definitnion
    }
    
    func shareService2() -> Definition
    {
        let service = Definition(withClass: Service.self)
        service.injectProperty("name", with: "Hello world")
        service.setScope(Definition.Scope.Singletone)
        return service
    }

    func shareService(withArgument:Int) -> Definition
    {
        return Definition(withClass: Service.self) { d in
            d.setScope(Definition.Scope.WeakSingletone)
        }
    }
    
    func man() -> Definition
    {
        return Definition(withClass: Man.self) { configuration in
            configuration.injectProperty("name", with: "Vit")
            configuration.injectProperty("brother", with: self.manWith("Alex"))
        }
    }
    
    func name() -> Definition
    {
        return Definition(withClass: String.self) { d in
           
        }
    }
    
    func arg1(name: String) -> Definition {
        return Definition(withClass: Man.self)
    }
    
    func arg2(name: String, name2: String,name3:String  , name5   :String) -> Definition {
        return Definition(withClass: Man.self)
    }

    func arg3(wname name:String,
                    name3 name2: String) -> Definition {
        return Definition(withClass: Man.self)
    }
    
    func arg4(wname name: String, _ name2: String) -> Definition {
        return Definition(withClass: Man.self)
    }
    
    func arg5(inout wname name: String, _ name2: String? = "213") -> Definition {
        return Definition(withClass: Man.self)
    }
    
    func arg6(inout name: String, _ name2: String? = "213") -> Definition {
        return Definition(withClass: Man.self)
    }
//
//    func component1() -> Definition
//    {
//        return Definition(withClass: Component.self) { d in
//            d.injectProperty("dependency", with: self.component2())
//        }
//    }
//    
//    func component2() -> Definition
//    {
//        return Definition(withClass: Component.self) { d in
//            d.injectProperty("dependency", with: self.component3())
//        }
//    }
//    
//    func component3() -> Definition
//    {
//        return Definition(withClass: Component.self) { d in
//            d.injectProperty("dependency", with: self.component1())
//        }
//    }
    
//
//    func twoPlusTwo(two: Int, plusTwo: Int) -> Int {
//        return two + two;
//    }
//    
//    func navigationController() -> Definition {
//        return Definition(withClass: Man.self) { d in
//            let age = 25
//            d.injectProperty("name", with: "Aleksey")
//            d.injectProperty("age", with: age)
//        }
//    }
//    
//    func navigationController2() -> Definition {
//        return Definition(withClass: Man.self) {
//            let age = 25
//            $0.injectProperty("name", with: "Aleksey")
//            $0.injectProperty("age", with: age)
//        }
//    }
//    

}