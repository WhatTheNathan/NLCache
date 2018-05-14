//
//  NLListNode.swift
//  NLCache
//
//  Created by Nathan on 13/05/2018.
//  Copyright © 2018 Nathan. All rights reserved.
//

import Foundation

internal class NLLinkedMapNode<T> : NSObject {
    
    var _key : String
    var _value : T
    var _cost : UInt
    var _time : TimeInterval
    
    weak var _pre : NLLinkedMapNode?
    weak var _next : NLLinkedMapNode?
    
    init(key: String,
         value: T,
         cost: UInt,
         time: TimeInterval) {
        self._key = key
        self._value = value
        self._cost = cost
        self._time = time
    }
}
