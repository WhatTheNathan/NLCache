//
//  NLDiskCache.swift
//  Demo
//
//  Created by Nathan on 18/05/2018.
//  Copyright © 2018 Nathan. All rights reserved.
//

import Foundation

// MARK: storage the diskcaches
var globalInstances = NSMapTable<NSString, NLDiskCache>.init(keyOptions: NSPointerFunctions.Options.strongMemory, valueOptions: NSPointerFunctions.Options.weakMemory, capacity: 0)

open class NLDiskCache {
// MARK: Open Property
    
// MARK: Private Property
    
    // Lock
    fileprivate let semaphoreLock = DispatchSemaphore(value: 1)
    
// MARK: Constructer and desctructer
    init() {
        
    }
}

// MARK: Lock Method
extension NLDiskCache {
    fileprivate func lock() {
        _ = semaphoreLock.wait(timeout: .distantFuture)
    }
    
    fileprivate func unlock() {
        semaphoreLock.signal()
    }
}
