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
    
// MARK: Public Property
    public var totalCount : UInt {
        get {
            lock()
            let count = linkedMap.totalCount
            unlock()
            return count
        }
    }
    
    public var totalCost : UInt {
        get {
            lock()
            let cost = linkedMap.totalCost
            unlock()
            return cost
        }
    }
    
// MARK: Private Property
    // Serial Queue
    var queue : DispatchQueue
    
    // LinkedMap
    var linkedMap : NLLinkedMap<Any>
    
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
    public func set(object: Any, forKey key: String) {
        lock()
        let node = NLLinkedMapNode(key: key, value: object, cost: 0, time: 120)
        linkedMap.insetNodeAtHead(node: node)
        unlock()
    }
    
    /**
     
     **/
    public func object(forKey key: String) -> Any? {
        var value : Any? = nil
        
        lock()
        let node = linkedMap._dic.object(forKey: key) as? NLLinkedMapNode<Any>
//        node?._time = CACurrentMediaTime()
        if let node = node {
            linkedMap.bringNodeToHead(node: node)
        }
        value = node?._value
        unlock()
        
        return value
    }
    
    /**
     
     **/
    public func containsObjectFor(key: String) -> Bool{
        var contains = false
        lock()
        let node = linkedMap._dic[key]
        if let _ = node {
            contains = true
        }
        unlock()
        return contains
    }
    
    /**
    
     **/
    public func removeObjectFor(key: String) {
        lock()
        let node = linkedMap._dic.object(forKey: key) as? NLLinkedMapNode<Any>
        if let node = node {
            linkedMap.remove(node: node)
        }
        unlock()
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
