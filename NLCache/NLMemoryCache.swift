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
 *
 * Thread Safety
 * For common write & read: semaphore lock & current thread
 * For auto release:
 * if async:
 *      Semaphore lock + concurrent queue
 * else if release on main thread:
 *      Semaphore lock + main thread
 *
 * QuestionMark: 异步到并行队列后加锁的读写效率如何?
 **/
open class NLMemoryCache {
    
// MARK: Open Property
    // shared instance
    open static let shared = NLMemoryCache()
    
// MARK: Private Property
    // Serial Queue
    var queue : DispatchQueue
    
    // LinkedMap
    var linkedMap : NLLinkedMap<AnyObject>
    
    // Lock
    fileprivate let semaphoreLock = DispatchSemaphore(value: 1)
    
    /* Designed constructer */
    private init() {
        queue = DispatchQueue(label: "com.nlcache." + String(describing: NLMemoryCache.self), qos: .default)
        linkedMap = NLLinkedMap.init()
    }
}

// MARK: Public Method
extension NLMemoryCache {
    /**
     - parameter object:
     - parameter key:
     **/
    public func set(object: AnyObject, for key: String) {
        
    }
    
    /**
     
     **/
    public func get(object: AnyObject, for key: String) {
        
    }
    
    /**
     
     **/
    public func containsObject(for key: String) -> Bool{
        return true
    }
}

// MARK: Lock Method
extension NLMemoryCache {
    fileprivate func lock() {
        _ = semaphoreLock.wait(timeout: .distantFuture)
    }
    
    fileprivate func unlock() {
        semaphoreLock.signal()
    }
}
