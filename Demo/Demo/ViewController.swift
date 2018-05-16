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
        
        /* initialize */
        let cache = NLMemoryCache.shared
        
        /* Test for set*/
        for index in 0...9 {
            print(index)
            cache.set(object: index, forKey: String(index))
        }
        
        /* Test for get*/
        for index in 0...9 {
            let value = cache.object(forKey: String(index))
        }
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

