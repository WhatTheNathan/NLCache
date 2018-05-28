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
//        testForMemory()
        testForDisk()
    }
    
    private func testForMemory() {
        // MARK: Test for MemoryCache
        /* initialize */
        let cache = NLMemoryCache.shared
        
        /* Test for set*/
        for index in 0...9 {
            cache.set(object: index, forKey: String(index))
        }
        var what = [1,2,3,4,5,6]
        cache.set(object: what, forKey: "test")
        what = cache.object(forKey: "test") as! [Int]
        print(what)
        if let value = cache.object(forKey: "123") as? Int {
            print(value)
        }
        
         /* Test for get */
        for index in 0...9 {
            let value = cache.object(forKey: String(index)) as? Int
            print(value)
        }
        
         /* Test for remove */
        cache.removeObjectFor(key: "1")
        print(cache.containsObjectFor(key: "1"))
        
         /* Test for removeAll */
        cache.removeAllObjects()
        for index in 0...9 {
            let value = cache.object(forKey: String(index)) as? Int
            print(value)
        }
        
         /* Test for trimAge */
        cache.ageLimit = 5
        for index in 0...9 {
            sleep(5)
            cache.set(object: index, forKey: String(index))
        }
        for index in 0...9 {
            print(cache.containsObjectFor(key: String(index)))
        }
        
         /* Test for trimCost */
        cache.costLimit = 30
        for index in 0...9 {
            print(index)
            cache.set(object: index, forKey: String(index), withCost: UInt(index))
        }
        for index in 0...9 {
            print(cache.containsObjectFor(key: String(index)))
        }
        
         /* Test for trimCount */
        cache.countLimit = 5
        for index in 0...9 {
            cache.set(object: index, forKey: String(index))
        }
        for index in 0...9 {
            print(cache.containsObjectFor(key: String(index)))
        }
    }


    // MARK: Test for DiskCache
    private func testForDisk() {
        if let basePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last {
            /* Test for disk(File) */
            let storage = NLKVStorage.init(basePath, .NLKVStorageTypeFile)
            let str = "Test"
            if let value = str.data(using: .utf8) {
                let isSuccess = storage.saveItem(withKey: "nll", value: value, fileName: "nll")
                print(isSuccess)
            }
            if let value = storage.getItemValue(forKey: "nll") {
                let ans = String.init(data: value, encoding: .utf8)
                print(ans)
            }
            if storage.itemExists(forKey: "nl") {
                print("true")
            }
            if let item = storage.getItem(forKey: "nl") {
                print(item._fileName)
            }
            
            /* Test for disk(sqlite3) */
//            let storage = NLKVStorage.init(basePath, .NLKVStorageTypeSQLite)
//            let str = "Test"
//            if let value = str.data(using: .utf8) {
//                let isSuccess = storage.saveItem(withKey: "nl", value: value)
////                let isSuccess1 = storage.saveItem(withKey: "nl1", value: value)
////                let isSuccess2 = storage.saveItem(withKey: "nl2", value: value)
////                let isSuccess3 = storage.saveItem(withKey: "nl3", value: value)
////                let isSuccess4 = storage.saveItem(withKey: "nl4", value: value)
////                let isSuccess5 = storage.saveItem(withKey: "nl5", value: value)
//                print(isSuccess)
//            }
//            if let value = storage.getItemValue(forKey: "nl") {
//                let ans = String.init(data: value, encoding: .utf8)
//                print(ans)
//            }
//            print(storage.itemExists(forKey: "nl"))
//            storage.removeItem(forKey: "nl")
//            print(storage.itemExists(forKey: "nl"))
//            print(storage.itemExists(forKey: "nl"))
//            storage.removeAllItem()
//            print(storage.itemExists(forKey: "nl1"))
        }
    }
}

