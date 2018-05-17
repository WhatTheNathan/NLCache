//
//  ViewController.swift
//  Benchmark
//
//  Created by Nathan on 16/05/2018.
//  Copyright © 2018 Nathan. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        benchmark()
    }
    
    func benchmark() {
        memeoryCacheBenchMark()
    }
    
    func memeoryCacheBenchMark() {
        // initialize
        let nl = NLMemoryCache.shared
        
        let keys = NSMutableArray.init()
        let values = NSMutableArray.init()
        for index in 0..<200000 {
            keys.add(String(index))
            values.add(index)
        }
        
        var begin: TimeInterval
        var end: TimeInterval
        var time: TimeInterval
        
        print("---------------------------------------")
        print("Memory cache set 200000 key-value pairs")
        begin = CACurrentMediaTime()
        for index in 0..<200000 {
            nl.set(object: values[index], forKey: keys[index] as! String)
        }
        end = CACurrentMediaTime()
        time = end - begin
        print("NLCache:     \(time)")
        
        print("---------------------------------------")
        print("Memory cache get 200000 key-value pairs")
        begin = CACurrentMediaTime()
        for index in 0..<200000 {
            nl.object(forKey: keys[index] as! String)
        }
        end = CACurrentMediaTime()
        time = end - begin
        print("NLCache:     \(time)")
        
        print("---------------------------------------")
        print("Memory cache get 200000 key-value pairs randomly")
        for index in 0..<200000 {
            keys.exchangeObject(at: index, withObjectAt: Int(arc4random()%200000))
        }
        
        begin = CACurrentMediaTime()
        for index in 0..<200000 {
            nl.object(forKey: keys[index] as! String)
        }
        end = CACurrentMediaTime()
        time = end - begin
        print("NLCache:     \(time)")
        
        print("---------------------------------------")
        print("Memory cache get 200000 key-value none exist")
        nl.removeAllObjects()
        begin = CACurrentMediaTime()
        for index in 0..<200000 {
            nl.object(forKey: keys[index] as! String)
        }
        end = CACurrentMediaTime()
        time = end - begin
        print("NLCache:     \(time)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

