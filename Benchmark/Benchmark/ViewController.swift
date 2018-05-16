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
        for index in 0..<100000 {
            let value = Data.init(count: index)
            keys.add(String(index))
            values.add(value)
        }
        
        var begin: TimeInterval
        var end: TimeInterval
        var time: TimeInterval
        
        print("Memory cache set 200000 key-value pairs")
        begin = CACurrentMediaTime()
        for index in 0..<100000 {
            nl.set(object: values[index], forKey: keys[index] as! String)
        }
        end = CACurrentMediaTime()
        time = end - begin
        print("NLCache:     \(time*1000)")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

