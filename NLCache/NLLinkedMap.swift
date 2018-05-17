//
//  NLDoubleLinkedList.swift
//  NLCache
//
//  Created by Nathan on 13/05/2018.
//  Copyright © 2018 Nathan. All rights reserved.
//

import Foundation
/**
 * a LinkedMap supported NLMemoryCache
 **/
internal class NLLinkedMap<T> {
    
    public typealias Node = NLLinkedMapNode<T>
    
    // Map
    var _dic : NSMutableDictionary
    
    // Most Recently Used
    weak var _head : Node?
    // Least Recently Used
    weak var _tail : Node?
    var totalCost : UInt = 0
    var totalCount : UInt = 0
    
    // MARK: Internal
    init() {
        _dic = NSMutableDictionary()
    }
    
    func insetNodeAtHead(node: Node) {
        // common process
        _dic.setObject(node, forKey: node._key as NSCopying)
        totalCost += node._cost
        totalCount += 1
        
        if _head != nil {
            node._next = _head
            _head?._pre = node
            _head = node
        } else {
            _head = node
            _tail = node
        }
    }
    
    func bringNodeToHead(node: Node) {
        if _head  == node {
            return
        }
        
        if _tail == node {
            _tail = node._pre
            _tail?._next = nil
        } else {
            _tail?._next?._pre = _tail?._pre
            _tail?._pre?._next = _tail?._next
        }
        node._next = _head
        node._pre = nil
        _head?._pre = node
        _head = node
    }
    
    func remove(node: Node) {
        // normal process
        _dic.removeObject(forKey: node._key)
        totalCount -= 1
        totalCost -= node._cost
        
        if((node._next) != nil) { node._next?._pre = node._pre }
        if((node._pre) != nil) { node._pre?._next = node._next }
        if(node == _head) { _head = node._next }
        if(node == _tail) { _tail = node._pre }
    }
    
    func removeTailNode() {
        guard let node = _tail else {
            return
        }
        _dic.removeObject(forKey: node._key)
        totalCount -= 1
        totalCost -= node._cost
        
        if(_head == _tail) {
            _head = nil
            _tail = nil
        } else {
            _tail = _tail?._pre
            _tail?._next = nil
        }
    }
    
    func removeAll() {
        totalCost = 0
        totalCount = 0
        _head = nil
        _tail = nil
        
        _dic.removeAllObjects()
    }
}
