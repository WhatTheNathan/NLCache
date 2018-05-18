//
//  NLKVStorage.swift
//  NLCache
//
//  Created by Nathan on 18/05/2018.
//  Copyright © 2018 Nathan. All rights reserved.
//

import Foundation

let dataDirectoryName = "data"
let trashDirectoryName = "trash"

/**
 key-value storage supports NLDiskCache
 */
class NLKVStorage {
    var _path : String
    var _dataPath : String
    var _trashPath : String
    var _type : NLKVStorageType
    
    init(_ path: String,
         _ type: NLKVStorageType) {
        self._type = type
        self._path = path
        self._dataPath = path + dataDirectoryName
        self._trashPath = path + trashDirectoryName
        
//        if (!FileManager.default.createDirectory(atPath: _path, withIntermediateDirectories: true, attributes: nil) ||
//            !FileManager.default.createDirectory(atPath: _dataPath, withIntermediateDirectories: true, attributes: nil) ||
//            !FileManager.default.createDirectory(atPath: _trashPath, withIntermediateDirectories: true, attributes: nil)) {
//            <#code#>
//        }
        
    }
}

// MARK: Public API
extension NLKVStorage {
    /**
     Save an item or update the item with 'key' if it already exists.
     */
    public func saveItem(item: NLKVStorageItem) -> Bool {
        return saveItem(withKey: item._key, value: item._value, fileName: item._fileName)
    }
    
    /**
     Save an item or update the item with 'key' if it already exists.This method will save the key-value pair to sqlite. If the `type` is
     YYKVStorageTypeFile, then this method will failed.
     - parameter key:  The key, should not be empty (nil or zero length).
     - parameter value: The key, should not be empty (nil or zero length).
     - return Whether succeed.
     */
    public func saveItem(withKey key: String, value: Data) -> Bool {
        return saveItem(withKey: key, value: value, fileName: nil)
    }
    
    /**
     Save an item or update the item with 'key' if it already exists.the `value` will be saved to file
     system if the `filename` is not empty, otherwise it will be saved to sqlite.
     - parameter key:  The key, should not be empty (nil or zero length).
     - parameter value: The value, should not be empty (nil or zero length).
     - return Whether succeed.
     */
    public func saveItem(withKey key: String, value: Data, fileName: String?) -> Bool {
//        let nskey = key as NSString
//        if nskey.length == 0 ||
        // write2file
        if let fileName = fileName {
            let nsFileName = fileName as NSString
            if nsFileName.length > 0 {
                
            }
        } else {
            
        }
        return true
    }
}

// MARK: File, Private Method
extension NLKVStorage {
    private func writeFile(withName fileName: String, data: Data) -> Bool {
        
        return true
    }
}

// MARK: DB, Private Method
extension NLKVStorage {
}
