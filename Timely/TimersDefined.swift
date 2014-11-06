//
//  TimersDefined.swift
//  Timely
//
//  Created by Andrew Platkin on 11/4/14.
//  Copyright (c) 2014 PlattypusLabs. All rights reserved.
//

import Foundation
import CoreData

class TimersDefined: NSManagedObject {

    @NSManaged var timerName: String
    @NSManaged var timerSeconds: NSNumber
    @NSManaged var startedIndicator: NSNumber
    @NSManaged var timeStarted: NSDate
    
    class func createInManagedObjectContext(moc: NSManagedObjectContext, name: String, seconds: Int) -> TimersDefined {
        let newTimer = NSEntityDescription.insertNewObjectForEntityForName("TimersDefined", inManagedObjectContext: moc) as TimersDefined
        newTimer.timerName = name
        newTimer.timerSeconds = seconds
        newTimer.startedIndicator = false
        newTimer.timeStarted = NSDate()
        
        return newTimer
    }
}
