//
//  NLKVStorage.swift
//  NLCache
//
//  Created by Nathan on 18/05/2018.
//  Copyright © 2018 Nathan. All rights reserved.
//

import Foundation
import SQLite3
import UIKit

let dataDirectoryName = "data"
let trashDirectoryName = "trash"
let dbFileName = "manifest.sqlite"

/**
 key-value storage supports NLDiskCache
 */
class NLKVStorage {
    var _path : String
    var _dataPath : String
    var _trashPath : String
    var _dbPath : String
    var _type : NLKVStorageType
    
    var _db : OpaquePointer?
    var _dbStmtCache : NSMutableDictionary
    
    init(_ path: String,
         _ type: NLKVStorageType) {
        self._type = type
        self._path = path
        self._dataPath = path.appending(dataDirectoryName)
        self._trashPath = path.appending(trashDirectoryName)
        self._dbPath = path.appending(dbFileName)
        self._dbStmtCache = NSMutableDictionary.init()
        
        do {
            try FileManager.default.createDirectory(atPath: _path, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: _dataPath, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.createDirectory(atPath: _trashPath, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            NSLog("Unable to create directory \(error.debugDescription)")
        }
        
        dbOpen()
    }
}

// MARK: Public API
extension NLKVStorage {
    // MARK: Save API
    /**
     Save an item or update the item with 'key' if it already exists.
     */
    public func saveItem(item: NLKVStorageItem) -> Bool {
        return saveItem(withKey: item._key, value: item._value, fileName: item._fileName)
    }
    
    /**
     Save an item or update the item with 'key' if it already exists.This method will save the key-value pair to sqlite. If the `type` is YYKVStorageTypeFile, then this method will failed.
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
        if key == "" {
            return false
        }
        // 1.对于File,如果fileName不为空,则写文件,成功也要写入数据库,若成功才成功,否则为失败
        //           如果fileName为空,失败
        // 2.对于SQLite,如果fileName为空，则直接写入db，不为空则文件和数据库都写
        // 3.对于mix,如果fileName不为空，则依然写文件数据库，为空则查询数据库，删除key对应文件,写入数据库
        if let fileName = fileName, fileName != "" {
            if !writeFile(withName: fileName, data: value) {
                return false
            }
            if !dbSave(withKey: key, value: value, fileName: fileName) {
                _ = deleteFile(withName: fileName)
                return false
            }
            return true
        } else {
            switch _type {
            case .NLKVStorageTypeFile:
                return false
            case .NLKVStorageTypeSQLite:
                return dbSave(withKey: key, value: value, fileName: "")
            case .NLKVStorageTypeMixed:
                let filename = dbGetFileName(withKey: key)
                if let filename = filename {
                    _ = deleteFile(withName: filename)
                }
                return dbSave(withKey: key, value: value, fileName: "")
            }
        }
    }
    
    // MARK: Get API
    /**
     Get item with a specified key.
     - parameter key: A specified key.
     */
    public func getItem(forKey key: String) -> NLKVStorageItem? {
        if key == "" {
            return nil
        }

        if let item = dbGetItem(withKey: key) {
            dbUpdateAccessTime(withKey: key)
            if item._fileName != "" {
                if let value = readFile(withName: item._fileName) {
                    item._value = value
                } else {
                    dbDeleteItem(withKey: key)
                    return nil
                }
            }
            return item
        }
        return nil
    }
    
    /**
     Get item value with a specified key.
     - parameter key: A specified key.
     */
    public func getItemValue(forKey key: String) -> Data? {
        if key == "" {
            return nil
        }
        var reValue : Data?
        switch _type {
        case .NLKVStorageTypeFile:
            if let fileName = dbGetFileName(withKey: key) {
                if let value = readFile(withName: fileName) {
                    reValue = value
                } else {
                    dbDeleteItem(withKey: key)
                    reValue = nil
                }
            }
        case .NLKVStorageTypeSQLite:
            reValue = dbGetValue(withKey: key)
        case .NLKVStorageTypeMixed:
            if let fileName = dbGetFileName(withKey: key) {
                if let value = readFile(withName: fileName) {
                    reValue = value
                } else {
                    dbDeleteItem(withKey: key)
                    reValue = nil
                }
            } else {
                reValue = dbGetValue(withKey: key)
            }
        }
        if let value = reValue {
            dbUpdateAccessTime(withKey: key)
        }
        return reValue
    }
}

// MARK: File, Private Method
extension NLKVStorage {
    private func writeFile(withName fileName: String, data: Data) -> Bool {
        let path = _dataPath.appending(fileName)
        do {
            try data.write(to: URL(fileURLWithPath: path))
        } catch {
            return false
        }
        return true
    }
    
    private func readFile(withName fileName: String) -> Data? {
        let path = _dataPath.appending(fileName)
        var file : Data
        do {
            file = try Data(contentsOf: URL(fileURLWithPath: path))
        } catch {
            return nil
        }
        return file
    }
    
    private func deleteFile(withName fileName: String) -> Bool {
        let path = _dataPath.appending(fileName)
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch {
            return false
        }
        return true
    }
    
}

// MARK: DB, Private Method
extension NLKVStorage {
    private func dbOpen() -> Bool {
        if _db != nil {
            return true
        }
        
        let result = sqlite3_open(_dbPath.cString(using: .utf8), &_db)
        if result == SQLITE_OK {
            return true
        } else {
            _db = nil
            return false
        }
    }
    
    private func dbClose() -> Bool {
        if _db == nil {
            return true
        }
        
        var result: Int32
        var retry = false
        var stmtFinalized = false
        
        repeat {
            retry = false
            result = sqlite3_close(_db)
            if result == SQLITE_BUSY || result == SQLITE_LOCKED {
                if !stmtFinalized {
                    stmtFinalized = true
                    while let stmt = sqlite3_next_stmt(_db, nil), stmt != nil {
                        sqlite3_finalize(stmt)
                        retry = true
                    }
                }
            } else if result != SQLITE_OK {
                
            }
        } while retry
        _db = nil
        _dbStmtCache.removeAllObjects()
        return true
    }
    
    private func dbSave(withKey key: String, value: Data, fileName: String) -> Bool {
        let sql = "insert or replace into manifest (key, filename, size, inline_data, modification_time, last_access_time,) values (?1, ?2, ?3, ?4, ?5, ?6);"
        let stmt = _dbStmtCache[sql] as? OpaquePointer
        if stmt == nil {
            return false
        }
        
        let timeStamp = CACurrentMediaTime() * 1000
        let nsData = value as NSData
        let size = nsData.length
        sqlite3_bind_text(stmt, 1, key.cString(using: .utf8), -1, nil)
        sqlite3_bind_text(stmt, 2, fileName.cString(using: .utf8), -1, nil)
        sqlite3_bind_int(stmt, 3, Int32(size))
        sqlite3_bind_blob(stmt, 4, nsData.bytes, Int32(size), nil)
        sqlite3_bind_int(stmt, 5, Int32(Int(timeStamp)))
        sqlite3_bind_int(stmt, 5, Int32(Int(timeStamp)))
        
        let result = sqlite3_step(stmt)
        if result != SQLITE_DONE {
            return false
        }
        return true
    }
    
    private func dbGetItem(withKey key: String) -> NLKVStorageItem? {
        let sql = "select key, filename, size, inline_data, modification_time, last_access_time from manifest where key = " + key
        let stmt = dbPrepareStmt(sql: sql)
        if let stmt = stmt {
            sqlite3_bind_text(stmt, 1, key.cString(using: .utf8), -1, nil)
            let result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                let item = dbGetItem(fromStmt: stmt)
                return item
            } else if result != SQLITE_DONE {
                return nil
            }
        }
        return nil
    }
    
    private func dbGetItem(fromStmt stmt: OpaquePointer) -> NLKVStorageItem? {
        var i : Int32 = 0
        var key = ""
        var value = Data.init()
        var fileName = ""
        
        let ckey = sqlite3_column_text(stmt, i)
        i += 1
        
        let filename = sqlite3_column_text(stmt, i)
        i += 1
        
        let size = sqlite3_column_int(stmt, i)
        i += 1
        
        let inline_data = sqlite3_column_blob(stmt, i)
        i += 1
        
        let modification_time = sqlite3_column_int(stmt, i)
        i += 1
        
        let last_access_time = sqlite3_column_int(stmt, i)
        i += 1
        
        if let ckey = ckey {
            key = String.init(cString: ckey)
        }
        
        if let data = inline_data {
            value = Data.init(bytes: data, count: Int(size))
        }
        
        if let name = filename {
            fileName = String.init(cString: name)
        }
        
        let item = NLKVStorageItem.init(key, value, UInt(size), fileName, UInt(modification_time), UInt(last_access_time))
        return item
    }
    
    private func dbPrepareStmt(sql: String) -> OpaquePointer? {
        if sql == "" {
            return nil
        }
        var stmt = _dbStmtCache[sql] as? OpaquePointer
        if stmt != nil {
            let result = sqlite3_prepare_v2(_db, sql.cString(using: .utf8), -1, &stmt, nil)
            if result != SQLITE_OK {
                return nil
            }
            _dbStmtCache.setObject(stmt!, forKey: sql as NSCopying)
        } else {
            sqlite3_reset(stmt)
        }
        return stmt
    }
    
    private func dbGetFileName(withKey key: String) -> String? {
        let sql = "select filename from manifest where key = ?1;"
        if let stmt = dbPrepareStmt(sql: sql) {
            sqlite3_bind_text(stmt, 1, key.cString(using: .utf8), -1, nil)
            let result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                if let name = sqlite3_column_text(stmt, 0) {
                    return String.init(cString: name)
                }
            }
        }
        return nil
    }
    
    private func dbGetValue(withKey key: String) -> Data? {
        let sql = "select inline_data from manifest where key = ?1;"
        if let stmt = dbPrepareStmt(sql: sql) {
            sqlite3_bind_text(stmt, 1, key.cString(using: .utf8), -1, nil)
            let result = sqlite3_step(stmt)
            if result == SQLITE_ROW {
                let bytes = sqlite3_column_bytes(stmt, 0)
                if let data = sqlite3_column_blob(stmt, 0), bytes > 0 {
                    return Data.init(bytes: data, count: Int(bytes))
                }
            }
        }
        return nil
    }
    
    private func dbUpdateAccessTime(withKey key: String) -> Bool {
        let sql = "update manifest set last_access_time = ?1 where key = ?2;"
        let timeStamp = CACurrentMediaTime() * 1000
        
        if let stmt = dbPrepareStmt(sql: sql) {
            sqlite3_bind_int(stmt, 1,  Int32(Int(timeStamp)))
            sqlite3_bind_text(stmt, 2, key.cString(using: .utf8), -1, nil)
            let result = sqlite3_step(stmt)
            if result != SQLITE_DONE {
                return false
            }
            return true
        }
        return false
    }
    
    private func dbDeleteItem(withKey key: String) -> Bool {
        let sql = "delete from manifest where key = ?1;"
        if let stmt = dbPrepareStmt(sql: sql) {
            sqlite3_bind_text(stmt, 1, key.cString(using: .utf8), -1, nil)
            let result = sqlite3_step(stmt)
            if result != SQLITE_DONE {
                return false
            }
        }
        return true
    }
}
