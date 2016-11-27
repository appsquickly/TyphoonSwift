//
//  ViewController.swift
//  TyphoonSwiftExample
//
//  Created by Aleksey Garbarev on 23/10/2016.
//  Copyright © 2016 AppsQuick.ly. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let man = CoreComponents.assembly.man()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        print("man.name: \(man.name)")
        print("man.bro.name: \(man.brother?.name)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

