//
//  TimerTableViewController.swift
//  Timely
//
//  Created by Andrew Platkin on 10/28/14.
//  Copyright (c) 2014 PlattypusLabs. All rights reserved.
//

import UIKit
import CoreData

//To determine when to hide navigation
var somethingAdded = false

//Timer variable
var timer = NSTimer()

//Determine if the timer variable has been started
var timerSet = false

class TimerTableViewController: UITableViewController {

    var timers  = [TimersDefined]()
    var activeTimers = 0
    
    lazy var managedObjectContext : NSManagedObjectContext? = {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        if let managedObjectContext = appDelegate.managedObjectContext {
            return managedObjectContext
        }
        else {
            return nil
        }
    }()

    @IBOutlet var timerTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchTimers()
        // To understand when the app returns from the background, so that timers can be started again
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"initialize", name: UIApplicationWillEnterForegroundNotification,object: nil)
    }
    
    func initialize() {
        startTimer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timers.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var myCell:TimerTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as TimerTableViewCell
        
        // Set activeTimers = 0
        //activeTimers = 0
        
        // Get the LogItem for this index
        let timerItem = timers[indexPath.row]
        
        var minutes = Int(timerItem.timerSeconds)/60
        myCell.detailLabel.text = "\(minutes) minutes"
        myCell.titleLabel.text = timerItem.timerName
        
        //Resets it if it is passed the time of expiration
        if timerItem.startedIndicator == 1 && (Int(timerItem.timerSeconds) - Int(round(NSDate().timeIntervalSinceDate(timerItem.timeStarted)))) <= 0 {
            timerItem.startedIndicator = false
        }
        
        //Kicks off timer if there is one needed
        if timerItem.startedIndicator == 1 && (Int(timerItem.timerSeconds) - Int(round(NSDate().timeIntervalSinceDate(timerItem.timeStarted)))) > 0 && timerSet == false {
            startTimer()
        }
        
        if timerItem.startedIndicator == 1 {
            myCell.accessoryType = UITableViewCellAccessoryType.None
            
            //Display New Counter
            var currentDate = NSDate()
            var startedDate = timerItem.timeStarted
            var seconds = Int(timerItem.timerSeconds) - Int(round(currentDate.timeIntervalSinceDate(startedDate)))
            var hours   = seconds / 3600
            var mins    = (seconds % 3600) / 60
            var secs    = seconds % 60
            
            //Format Approriately
            var displayhours:String = trimTime("\(hours)")
            var displaymins:String  = trimTime("\(mins)")
            var displaysecs:String  = trimTime("\(secs)")
            
            myCell.countdownLabel.text = "\(displayhours):\(displaymins):\(displaysecs)"
            
            println("Seconds remaining: \(seconds)")
            //Reset to not active if the seconds go to 0
            if seconds == 1 {
                timerItem.startedIndicator = false
                //Kick off an alert
                //alertUserAboutTimer()
            }
            
            activeTimers++
            
        } else {
            myCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            myCell.countdownLabel.text = ""
        }

        //Deactivate the NSTimer if there are no currently running ones
        if activeTimers == 0 && timerSet {
            stopTimer()
            timerSet = false
        }
        
        var managedObject = timerItem
        
        if managedObject.hasChanges {
            save()
        }
        
        return myCell

    }
    
    //Enable editing of the cells
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    //Define the actions that can happen when sliding left on a table
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        
        var editAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Edit", handler: {
            (action: UITableViewRowAction!, indexPath: NSIndexPath!) in
            println("Triggered edit action \(action) atIndexPath: \(indexPath)")
            return
        })
        
        editAction.backgroundColor = UIColor.grayColor()
        
        var endAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "End", handler: {
            (action: UITableViewRowAction!, indexPath: NSIndexPath!) in
            println("Triggered end action \(action) atIndexPath: \(indexPath)")
            self.endTimer(indexPath)
            return
        })
        
        endAction.backgroundColor = UIColor.orangeColor()
        
        var deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler: {
            (action: UITableViewRowAction!, indexPath: NSIndexPath!) in
            println("Triggered delete action \(action) atIndexPath: \(indexPath)")
            self.deleteTimer(indexPath)
            return
        })
        
        deleteAction.backgroundColor = UIColor.redColor()
        
        //startTimer()
        
        return [deleteAction, endAction, editAction]
    }
    
    override func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        stopTimer()
    }
    
    //After any edits have/haven't been made, start the timer back up
    override func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        startTimer()
    }
    
    //Needed to display the editing buttons for the table
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        return
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Create timer if one was not created
        if timerSet == false {
            startTimer()
        }
        
        var cell:TimerTableViewCell = tableView.cellForRowAtIndexPath(indexPath)! as TimerTableViewCell
        cell.accessoryType = UITableViewCellAccessoryType.None
        
        // Get the LogItem for this index
        let timerItem = timers[indexPath.row]
        
        var seconds = Int(timerItem.timerSeconds)
        var hours   = seconds / 3600
        var mins    = (seconds % 3600) / 60
        var secs    = seconds % 60
        
        //Format Approriately
        var displayhours:String = trimTime("\(hours)")
        var displaymins:String  = trimTime("\(mins)")
        var displaysecs:String  = trimTime("\(secs)")
        
        cell.countdownLabel.text = "\(displayhours):\(displaymins):\(displaysecs)"
        
        //Start the timer by setting the array index to true
        timerItem.startedIndicator = true
        
        //Modify start time in Array to the current time
        let startTime = NSDate()
        timerItem.timeStarted = startTime
        
        //Update in persistent storage
        var managedObject = timerItem
        managedObject.setValue(true, forKey: "startedIndicator")
        managedObject.setValue(NSDate(), forKey: "timeStarted")
        save()
        
        //At this point the timers will be refreshed from the newly saved data
        fetchTimers()
        
        //Get the date in which the timer should show the notification (Seconds plus the time started)
        var fireDate = startTime.dateByAddingTimeInterval(Double(timerItem.timerSeconds))
        
        //Create the local notification
        scheduleLocalAlert(fireDate,timerName: timerItem.timerName)
    }
    
    override func viewWillAppear(animated: Bool) {
        //Used to hide navigation once the seque returns after a value has been added
        if somethingAdded {
            self.navigationItem.hidesBackButton = true
        }
        somethingAdded = false
    }
    
    //Used by the timer to refresh the table values
    func runCounter() {
        timerTable.reloadData()
    }

    //For formatting the numbers derived from seconds. This is leveraged when displaying the running clock.
    func trimTime(timeValue: String) -> String {
        
        var display = String()
        
        //For printing numbers with an additional zero if they only have one value (i.e. 7 becomes 07)
        if countElements("\(timeValue)") == 1 {
            display = "0\(timeValue)"
        } else {
            display = "\(timeValue)"
        }
        
        return display
    }

    //Used to retrieve the latest from TimersDefined and Insert the results into the timers array
    func fetchTimers() -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "TimersDefined")
        
        // Create a sort descriptor object that sorts on the "timerName"
        // property of the Core Data object
        let sortDescriptor = NSSortDescriptor(key: "timerName", ascending: true)
        
        // Set the list of sort descriptors in the fetch request,
        // so it includes the sort descriptor
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [TimersDefined] {
            timers = fetchResults
        }
        return true
    }
    
    //Used to save to Managed Object Context (Updating values)
    func save() {
        var error : NSError?
        if(managedObjectContext!.save(&error) ) {
            println(error?.localizedDescription)
        }
    }
    
    //Used to create a timer
    func startTimer() {
        if timer.valid == false {
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "runCounter", userInfo: nil, repeats: true)
            timerSet = true
            println("Timer Started")
        }
    }
    
    //Used to stop a timer
    func stopTimer() {
        timer.invalidate()
        timerSet = false
        println("Timer Stopped")
    }
    
    //Function used to delete the timer from the table and reset the local notifications
    func deleteTimer(indexPath: NSIndexPath) {
        // Find the LogItem object the user is trying to delete
        let timerToDelete = self.timers[indexPath.row]
        
        // Delete it from the managedObjectContext
        managedObjectContext?.deleteObject(timerToDelete)
        
        // Refresh the table view to indicate that it's deleted
        fetchTimers()
        
        // Tell the table view to animate out that row
        [timerTable .deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)]
        
        // Save changes
        save()
    }
    
    func endTimer(indexPath: NSIndexPath) {
        let timerToEnd = self.timers[indexPath.row]
        
        //Update in persistent storage
        var managedObject = timerToEnd
        managedObject.setValue(false, forKey: "startedIndicator")
        save()
        
        //Reload timer values into array
        fetchTimers()
    }
    
    //Used to schedule an alert to show up when the timer runs out
    func scheduleLocalAlert(dateFinished: NSDate, timerName: String) {
        var alert:UILocalNotification = UILocalNotification()
        
        alert.fireDate = dateFinished
        alert.timeZone = NSTimeZone.defaultTimeZone()
        alert.repeatInterval = NSCalendarUnit.allZeros
        alert.soundName = UILocalNotificationDefaultSoundName
        alert.alertBody = "Your \"\(timerName)\" timer has gone off"
        
        println("Created timer for \(dateFinished)")
        
        UIApplication.sharedApplication().scheduleLocalNotification(alert)
    }
    
    func deleteScheduledAlert(uniqueIdentifier: Int) {
        
    }
}
