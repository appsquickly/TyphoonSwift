//
//  Assembly.swift


import Foundation

class ViewsFactory : Assembly
{
    
}

class CoreComponents : Assembly {

    var relatedAssembly: ViewsFactory?
    
    func manWith(name: String) -> Definition {
        return Definition(withClass: Man.self) {
            $0.injectProperty("name", with: name)
            $0.setScope(Definition.Scope.ObjectGraph)
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