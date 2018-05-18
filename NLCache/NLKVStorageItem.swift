//
//  NLKVStorageItem.swift
//  NLCache
//
//  Created by Nathan on 18/05/2018.
//  Copyright © 2018 Nathan. All rights reserved.
//

import Foundation

enum NLKVStorageType: UInt {
    case NLKVStorageTypeFile = 0
    case NLKVStorageTypeSQLite = 1
    case NLKVStorageTypeMixed = 2
}

class NLKVStorageItem {
    
    var _key : String
    var _value : Data
    var _fileName : String
    var _size : UInt
    var _modTime : UInt
    var _accessTime : UInt
    
    init(_ key: String,
         _ value: Data,
         _ size: UInt,
         _ fileName: String,
         _ modTime: UInt,
         _ accessTime: UInt) {
        self._key = key
        self._value = value
        self._fileName = fileName
        self._size = size
        self._modTime = modTime
        self._accessTime = accessTime
    }
}
