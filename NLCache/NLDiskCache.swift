//
//  NLDiskCache.swift
//  Demo
//
//  Created by Nathan on 18/05/2018.
//  Copyright © 2018 Nathan. All rights reserved.
//

import Foundation

// MARK: storage the diskcaches
//var globalInstances = NSMapTable<NSString, NLDiskCache>.init(keyOptions: NSPointerFunctions.Options.strongMemory, valueOptions: NSPointerFunctions.Options.weakMemory, capacity: 0)

open class NLDiskCache {
// MARK: Open Property
    
// MARK: Private Property
    private var _path: String
    private var _threshold: UInt
    
    // kv
    private var _kv : NLKVStorage
    
    // Serial Queue
    var queue : DispatchQueue
    
    // Lock
    fileprivate let semaphoreLock = DispatchSemaphore(value: 1)
    
// MARK: Constructer and desctructer
    init(_ path: String,
         _ threshold: UInt = 1024 * 20) {
        var type: NLKVStorageType
        if threshold == 0 {
            type = .NLKVStorageTypeFile
        } else if threshold == UInt.max {
            type = .NLKVStorageTypeSQLite
        } else {
            type = .NLKVStorageTypeMixed
        }
        
        _kv = NLKVStorage.init(path, type)
        self._path = path
        self._threshold = threshold
        queue = DispatchQueue(label: "com.nlcache.disk" + String(describing: NLDiskCache.self), qos: .default)
    }
}

// MARK: Public Method For get & set & remove
extension NLDiskCache {
    
    /**
     Sets the value of the specified key in the cache.
     This method may blocks the calling thread until file write finished.
     - parameter object: The object to be stored in the cache. If nil, it calls `removeObjectForKey:`.
     - parameter key:    The key with which to associate the value. If nil, this method has no effect.
     */
    public func set(object: NSCoding, forKey key: String) {
        if key == "" {
            return
        }
        
        var value = NSKeyedArchiver.archivedData(withRootObject: object)
        let nsValue = value as NSData
        let fileName = ""
        if _kv._type != .NLKVStorageTypeSQLite, nsValue.length > _threshold {
            fileName = fileName(foeKey: key)
        }
        
        lock()
        _kv.saveItem(withKey: key, value: value, fileName: fileName)
        unlock()
    }
    
    /**
     Sets the value of the specified key in the cache.
     This method may blocks the calling thread until file write finished.
     - parameter key: A string identifying the value. If nil, just return nil.
     */
    public func object(forKey key: String) -> NSCoding? {
        if key == "" {
            return nil
        }
        lock()
        let item = _kv.getItem(forKey: key)
        unlock()
        
        var object : NSCoding?
        if let value = item?._value {
            object = NSKeyedUnarchiver.unarchiveObject(with: value)
        }
        return object
    }
    
    /**
     Removes the value of the specified key in the cache.
     This method may blocks the calling thread until file delete finished.
     - parameter key: The key identifying the value to be removed. If nil, this method has no effect.
     */
    public func removeObject(forKey key: String) {
        if key == "" {
            return
        }
        lock()
        _kv.removeItem(forKey: key)
        unlock()
    }
}

// MARK: Private Method
extension NLDiskCache {
    private func fileName(forKey key: String) -> Stirng {
        return NLStringMD5(str: key)
    }
    
    private func NLStringMD5(str: String) -> String {
        let cString = str.cStringUsingEncoding(NSUTF8StringEncoding)
        let length = CUnsignedInt(
            str.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        )
        let result = UnsafeMutablePointer<CUnsignedChar>.alloc(
            Int(CC_MD5_DIGEST_LENGTH)
        )
        
        CC_MD5(cString!, length, result)
        
        return String(format:
            "%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                      result[0], result[1], result[2], result[3],
                      result[4], result[5], result[6], result[7],
                      result[8], result[9], result[10], result[11],
                      result[12], result[13], result[14], result[15])
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
