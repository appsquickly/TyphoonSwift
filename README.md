# TyphoonSwift

This is alpha version. Works with Xcode 8.1 and Swift 3.


# Installation

```
brew install appsquickly/core/typhoon
```

# Concept

TyphoonSwift uses code generation to build your assembly. 


# Project setup

- Setup typhoon to run with your Swift project

go to your project directory and run:

```
typhoon setup
```

that makes `Typhoon.plist` file with settings.

- Run typhoon monitor

```
typhoon run
```

- Add generated files to your project.

Just drag results directory to your project ( see `resultDirPath` inside `Typhoon.plist` ). It contains activated assemblies built from your assemblies and tiny typhoon runtime.

# How to use

make sure that typhoon is up and running ( `typhoon run` command), then you can create assemblies inside your assemblies directory.
Assemblies syntax is very similar to Typhoon Objc:

```swift
class CoreComponents : Assembly {
        
    func manWith(_ name: String) -> Definition {
        return Definition(withClass: Man.self) {
            $0.injectProperty("name", with: name)
            $0.setScope(Definition.Scope.ObjectGraph)
            $0.injectProperty("brother", with: self.man())
        }
    }
    
    func man() -> Definition {
        return Definition(withClass: Man.self) { configuration in
            configuration.injectProperty("name", with: "John")
            configuration.injectProperty("brother", with: self.manWith("Alex"))
        }
    }
 
    func manWithInitializer() -> Definition {
        return Definition(withClass: Man.self) {
            $0.setScope(Definition.Scope.Prototype)
            $0.useInitializer("init(withName:)", with: { (m) in
                m.injectArgument("Tom")
            })
            $0.injectMethod("setAdultAge")
            $0.injectMethod("setValues(_:withAge:)") { (m) in
                m.injectArgument("John")
                m.injectArgument(21)
            }
        }
    }
}
```

After you've done with assemblies, you should activate Typhoon (That instantiates all eager singletones)

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        Typhoon.activateAssemblies()
        return true
}
```

That's all, now you can inject your components anywhere in your project, just like:

```swift
class ViewController: UIViewController {
    let man = CoreComponents.assembly.man()   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        print("man.name=\(man.name)")
    }
}
```

You can resolve all your definition through
<Assembly-Class>.assembly.<Definition-Method()>

Generated assembly has all your definitions methods, plus additional ways to resolve.
See examples below:

```swift

// Resovle using definition method

let man = CoreComponents.assembly.manWithInitializer()

// Get all components matching Type
let men = CoreComponents.assembly.allComponentsForType() as [Man]

// Resolve by Key
let keyedMen = CoreComponents.assembly.component(forKey: "man") as Man?

// Inject using instance type
var woman = Woman()
CoreComponents.assembly.inject(&woman)

// Resolve by Type
let byTypeWoman = CoreComponents.assembly.componentForType() as Woman?

```

If you still have questions how to use it, try Example project (see Example subdirectory)
