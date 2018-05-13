//
//  NLMemoryCache.swift
//  NLCache
//
//  Created by Nathan on 13/05/2018.
//  Copyright © 2018 Nathan. All rights reserved.
//

import Foundation

/**
 * NLMemoryCache is a fast in-memory cache that stores key-value pairs
 **/
open class NLMemoryCache {
    
    // shared instance
    static let shared = NLMemoryCache()
    
    //
//    fileprivate queue = 
    
    // Lock
    fileprivate let semaphoreLock = DispatchSemaphore(value: 1)
    
    /* Designed constructer */
    private init() {
        
    }
}

/**
 * Lock for thread-safe
 **/
extension NLMemoryCache {
    fileprivate func lock() {
        _ = semaphoreLock.wait(timeout: .distantFuture)
    }
    
    fileprivate func unlock() {
        semaphoreLock.signal()
    }
}
