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
 * For common write & read:
 *     semaphore lock & current thread
 * Note: Memory access = High-performance
 * For auto release:
 *     async + Semaphore lock + concurrent queue
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
    
// MARK: Private vars with Public get & set access
    
    /**
     The maximum number of objects the cache should hold.
     **/
    private var _countLimit : UInt = UInt.max
    
    public var countLimit : UInt {
        set {
            lock()
            _countLimit = newValue
            unlock()
        }
        get {
            lock()
            let countLimit = _countLimit
            unlock()
            return countLimit
        }
    }
    
    /**
     The maximum total cost that the cache can hold before it starts evicting objects.
     **/
    private var _costLimit : UInt = UInt.max
    
    public var costLimit : UInt {
        set {
            lock()
            _costLimit = newValue
            unlock()
        }
        get {
            lock()
            let costLimit = _costLimit
            unlock()
            return costLimit
        }
    }
    
    /**
     The maximum expiry time of objects in cache.
     **/
    private var _ageLimit : UInt = UInt.max
    
    public var ageLimit : UInt {
        set {
            lock()
            _ageLimit = newValue
            unlock()
        }
        get {
            lock()
            let ageLimit = _ageLimit
            unlock()
            return ageLimit
        }
    }
    
    /**
     The auto trim check time interval in seconds.
     The default value is 5.0.
     **/
    private var _autoTrimInterval : TimeInterval = 5.0
    
    public var autoTrimInterval : TimeInterval {
        set {
            lock()
            _autoTrimInterval = newValue
            unlock()
        }
        get {
            lock()
            let autoTrimInterval = _autoTrimInterval
            unlock()
            return autoTrimInterval
        }
    }
    
    /**
     If `true`, the cache will remove all objects when the app receives a memory warning.
     The default value is true.
     **/
    private var _shouldRemoveAllObjectsOnMemoryWarning : Bool = true
    
    public var shouldRemoveAllObjectsOnMemoryWarning : Bool {
        set {
            lock()
            _shouldRemoveAllObjectsOnMemoryWarning = newValue
            unlock()
        }
        get {
            lock()
            let shouldRemoveAllObjectsOnMemoryWarning = _shouldRemoveAllObjectsOnMemoryWarning
            unlock()
            return shouldRemoveAllObjectsOnMemoryWarning
        }
    }
    
    /**
     If `true`, The cache will remove all objects when the app enter background.
     The default value is `YES`.
     */
    private var _shouldRemoveAllObjectsWhenEnteringBackground : Bool = true
    
    public var shouldRemoveAllObjectsWhenEnteringBackground : Bool {
        set {
            lock()
            _shouldRemoveAllObjectsWhenEnteringBackground = newValue
            unlock()
        }
        get {
            lock()
            let shouldRemoveAllObjectsWhenEnteringBackground = _shouldRemoveAllObjectsWhenEnteringBackground
            unlock()
            return shouldRemoveAllObjectsWhenEnteringBackground
        }
    }
    
// MARK: Private Property
    // Serial Queue
    var queue : DispatchQueue
    
    // LinkedMap
    var linkedMap : NLLinkedMap<Any>
    
    // Lock
    fileprivate let semaphoreLock = DispatchSemaphore(value: 1)
    
// MARK: Designed Constructer & Destructer
    private init() {
        queue = DispatchQueue(label: "com.nlcache." + String(describing: NLMemoryCache.self), qos: .default)
        linkedMap = NLLinkedMap.init()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidReceiveMemoryWarningNotification),
                                               name:NSNotification.Name.UIApplicationDidReceiveMemoryWarning,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackgroundNotification),
                                               name: NSNotification.Name.UIApplicationDidEnterBackground,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.UIApplicationDidEnterBackground,
                                                  object: nil)
    }
}

// MARK: Public Method For get & set & remove
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
    
    /**
     
     **/
    public func removeAllObjects() {
        lock()
        linkedMap.removeAll()
        unlock()
    }
}

// MARK: Public Method For Trim
extension NLMemoryCache {
    /**
     
     **/
//    public func trimToCount()
}

// MARK: Private Method
extension NLMemoryCache {
    @objc fileprivate func appDidReceiveMemoryWarningNotification() {
        if shouldRemoveAllObjectsOnMemoryWarning {
            removeAllObjects()
        }
    }
    
    @objc fileprivate func appDidEnterBackgroundNotification() {
        if shouldRemoveAllObjectsWhenEnteringBackground {
            removeAllObjects()
        }
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
