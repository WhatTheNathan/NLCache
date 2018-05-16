//
//  ViewController.swift
//  Demo
//
//  Created by Nathan on 14/05/2018.
//  Copyright © 2018 Nathan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let cache = NLMemoryCache.shared
        print("what")
        cache.set(object: "haha", forKey: "1")
        let object = cache.object(forKey: "1")
        print(cache.containsObjectFor(key: "1"))
        cache.removeObjectFor(key: "1")
        print(cache.containsObjectFor(key: "1"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

