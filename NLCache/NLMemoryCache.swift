//
//  NLMemoryCache.swift
//  NLCache
//
//  Created by Nathan on 13/05/2018.
//  Copyright © 2018 Nathan. All rights reserved.
//

import Foundation
import UIKit

/**
 * NLMemoryCache is a fast in-memory cache that stores key-value pairs
 *
 * Thread Safety
 * For common write & read:
 *     semaphore lock & current thread
 * Note: Memory access is High-performance
 *
 * QuestionMark: 异步到并行队列后加锁的读写效率如何?
 * QuestionMark: 是否需要更底层的存储与释放?
 */
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
    private var _ageLimit : TimeInterval = DBL_MAX
    
    public var ageLimit : TimeInterval {
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
     The default value is `true`.
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
        
        startAutoTrim()
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
     Sets the value of the specified key in the cache, and associates the key-value
     pair with the specified cost.
     - parameter object:  The object to store in the cache.
     - parameter key:     The key with which to associate the value.
     - parameter cost:    The cost with which to associate the key-value pair.
     */
    public func set(object: Any, forKey key: String, withCost cost: UInt = 0) {
        lock()
        let now = CACurrentMediaTime()
        let node = linkedMap._dic[key]
        // if already exists
        if let node = node as? NLLinkedMapNode<Any> {
            linkedMap.totalCost -= node._cost
            linkedMap.totalCost += cost
            node._cost = cost
            node._time = now
            node._value = object
            linkedMap.bringNodeToHead(node: node)
        } else {
            let newNode = NLLinkedMapNode.init(key: key, value: object, cost: cost, time: now)
            linkedMap.insetNodeAtHead(node: newNode)
        }
        if linkedMap.totalCount > _countLimit {
            queue.async {
                self.trimToCount()
            }
        }
        if linkedMap.totalCost > _costLimit {
            queue.async {
                self.trimToCost()
            }
        }
        unlock()
    }
    
    /**
     Returns the value associated with a given key.
     - parameter key:    An object identifying the value.
     */
    public func object(forKey key: String) -> Any? {
        var value : Any? = nil
        
        lock()
        let node = linkedMap._dic.object(forKey: key) as? NLLinkedMapNode<Any>
        node?._time = CACurrentMediaTime()
        if let node = node {
            linkedMap.bringNodeToHead(node: node)
        }
        value = node?._value
        unlock()
        
        return value
    }
    
    /**
     Returns a Boolean value that indicates whether a given key is in cache.
     - parameter key:    key An object identifying the value.
     */
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
     Removes the value of the specified key in the cache.
     - parameter key:    key An object identifying the value.
     */
    public func removeObjectFor(key: String) {
        lock()
        let node = linkedMap._dic.object(forKey: key) as? NLLinkedMapNode<Any>
        if let node = node {
            linkedMap.remove(node: node)
        }
        unlock()
    }
    
    /**
     Removes all the key-value pairs in the cache.
     */
    public func removeAllObjects() {
        lock()
        linkedMap.removeAll()
        unlock()
    }
}

// MARK: Public Method For Trim
extension NLMemoryCache {
    /**
     Removes objects from the cache with LRU, until the `totalCount` is below or equal to
     the specified value.
     */
    public func trimToCount() {
        var isFinish = false
        lock()
        if _countLimit == 0 {
            linkedMap.removeAll()
            isFinish = true
        } else if linkedMap.totalCount <= _countLimit {
            isFinish = true
        }
        unlock()
        
        if isFinish {
            return
        }
        lock()
        while !isFinish {
            if linkedMap.totalCount > _countLimit {
                linkedMap.removeTailNode()
            } else {
                isFinish = true
            }
        }
        unlock()
    }
    
    /**
     Removes objects from the cache with LRU, until the `totalCost` is or equal to
     the specified value.
     */
    public func trimToCost() {
        var isFinish = false
        lock()
        if _costLimit == 0 {
            linkedMap.removeAll()
            isFinish = true
        } else if linkedMap.totalCost <= _costLimit {
            isFinish = true
        }
        unlock()
        
        if isFinish {
            return
        }
        lock()
        while !isFinish {
            if linkedMap.totalCost > _costLimit {
                linkedMap.removeTailNode()
            } else {
                isFinish = true
            }
        }
        unlock()
    }
    
    /**
     Removes objects from the cache with LRU, until all expiry objects removed by the
     specified value.
     */
    public func trimToAge() {
        var isFinish = false
        lock()
        let now = CACurrentMediaTime()
        if _ageLimit <= 0 {
            linkedMap.removeAll()
            isFinish = true
        } else if linkedMap._tail == nil {
            isFinish = true
        } else if let tail = linkedMap._tail, now - tail._time <= _ageLimit {
            isFinish = true
        }
        unlock()
        
        if isFinish {
            return
        }
        
        lock()
        while !isFinish {
            if let node = linkedMap._tail, now - node._time > _ageLimit {
                linkedMap.removeTailNode()
            } else {
                isFinish = true
            }
        }
        unlock()
    }
}

// MARK: Private Method
extension NLMemoryCache {
    @objc fileprivate func appDidReceiveMemoryWarningNotification() {
        if _shouldRemoveAllObjectsOnMemoryWarning {
            removeAllObjects()
        }
    }
    
    @objc fileprivate func appDidEnterBackgroundNotification() {
        if _shouldRemoveAllObjectsWhenEnteringBackground {
            removeAllObjects()
        }
    }
    
    private func startAutoTrim() {
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + _autoTrimInterval, qos: .background) {
            self.trimInBackground()
            self.startAutoTrim()
        }
    }
    
    private func trimInBackground() {
        queue.async {
            self.trimToCost()
            self.trimToCount()
            self.trimToAge()
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
