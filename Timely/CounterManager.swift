//
//  CounterManager.swift
//  Timely
//
//  Created by Andrew Platkin on 10/30/14.
//  Copyright (c) 2014 PlattypusLabs. All rights reserved.
//

import Foundation

// This needs to be delcared at global scope, serving as "singleton" instance of TimerManager
let counterManager = CounterManager()
var _counterTable = [Int: Int]()

class CounterManager {
    
    /*! Schedule a timer and return an integer that represents id of the timer
    */
    func runCounter(id: Int) -> Int {
        if _counterTable[id] == nil {
            var counter = 0
            _counterTable[id] = counter
        } else {
            var counter:Int = _counterTable[id]! + 1
            _counterTable[id] = counter
        }
        
        return _counterTable[id]!
    }
}