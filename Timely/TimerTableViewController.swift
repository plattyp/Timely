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

class TimerTableViewController: UITableViewController {

    //Variables needed to run actions within the Class
    var timers  = [TimersDefined]()
    var activeTimers = 0
    var label:UILabel = UILabel()
    var arrow:UIImageView = UIImageView()
    
    //Variables to store selected information about a given timer for Segues
    var timerSelectedRow = 0
    var timerEditing = false
    
    //Needed to create a ManagedObjectContext so that timers can be modified later
    lazy var managedObjectContext : NSManagedObjectContext? = {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        if let managedObjectContext = appDelegate.managedObjectContext {
            return managedObjectContext
        }
        else {
            return nil
        }
    }()

    //Outlet for the UITAbleView so that it can be manipulated below
    @IBOutlet var timerTable: UITableView!

    
    //
    // All standard methods for controlling the view
    //
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchTimers()
        
        //Set Active Timers to 0
        activeTimers = 0
        
        //Default the table view to have a footer with a White background to not show empty cells
        var tblView = UIView(frame: CGRectZero)
        timerTable.tableFooterView = tblView
        timerTable.tableFooterView?.hidden = true
        timerTable.backgroundColor = UIColor.whiteColor()
        
        //If no timers are available (e.g. none have been created), then show message accordingly
        showHideNoDataMessage()

        //To understand when the app returns from the background, so that timers can be started again
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"initialize", name: UIApplicationWillEnterForegroundNotification,object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        //Used to hide navigation once the segue returns after a value has been added
        if somethingAdded {
            self.navigationItem.hidesBackButton = true
            initialize()
        }
        somethingAdded = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func initialize() {
        startTimer()
    }

    
    //
    // All methods for controlling the table
    //
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timers.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var myCell:TimerTableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as TimerTableViewCell
        
        // Get the timer for this index
        let timerItem = timers[indexPath.row]
        
        var minutes = Int(timerItem.timerSeconds)/60
        
        //Handles the s after minutes if total minutes greater than 1
        var pluralCharacter = ""
        if minutes > 1 {
            pluralCharacter = "s"
        }
        
        //Set the standard Cell fields
        myCell.detailLabel.text = "\(minutes) minute\(pluralCharacter)"
        myCell.titleLabel.text = timerItem.timerName
        
        //Resets it if it is passed the time of expiration
        if timerItem.startedIndicator == 1 && (Int(timerItem.timerSeconds) - Int(round(NSDate().timeIntervalSinceDate(timerItem.timeStarted)))) <= 0 {
            timerItem.startedIndicator = false
        }
        
        //Kicks off timer if there is one needed
        if timerItem.startedIndicator == 1 && (Int(timerItem.timerSeconds) - Int(round(NSDate().timeIntervalSinceDate(timerItem.timeStarted)))) > 0 && timer.valid == false {
            startTimer()
        }
        
        if timerItem.startedIndicator == 1 {
            myCell.accessoryType = UITableViewCellAccessoryType.None
            
            //Calculate difference in time
            var currentDate = NSDate()
            var startedDate = timerItem.timeStarted
            var seconds = Int(timerItem.timerSeconds) - Int(round(currentDate.timeIntervalSinceDate(startedDate)))

            //Set the label to display the newly updated time
            myCell.countdownLabel.text = displayTicker(seconds)
            
            //Handle if the titleLabel is to large with the running timer
            if countElements(timerItem.timerName) > 20 {
                myCell.titleLabel.text = "\(timerItem.timerName.substringWithRange(Range(start: timerItem.timerName.startIndex,end: advance(timerItem.timerName.startIndex, 20)))).."
            }
            
            //Reset to not active if the seconds go to 0
            if seconds == 1 {
                timerItem.startedIndicator = false
            }
        } else {
            myCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            myCell.countdownLabel.text = ""
            
            //Handle if the titleLabel is to large for the cell
            if countElements(timerItem.timerName) > 33 {
                myCell.titleLabel.text = "\(timerItem.timerName.substringWithRange(Range(start: timerItem.timerName.startIndex,end: advance(timerItem.timerName.startIndex, 32)))).."
            }
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
        
        let timerItem = timers[indexPath.row]
        
        var editAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Edit", handler: {
            (action: UITableViewRowAction!, indexPath: NSIndexPath!) in
            println("Triggered edit action \(action) atIndexPath: \(indexPath)")
            
            //Set variables to be passed to Segue
            self.timerSelectedRow = indexPath.row
            self.timerEditing  = true
            
            //Perform the segue
            self.performSegueWithIdentifier("editTimerSegue", sender: self)
            
            return
        })
        
        editAction.backgroundColor = UIColor(red: 0.945, green: 0.620, blue: 0.000, alpha: 1.00)
        
        var endAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "End", handler: {
            (action: UITableViewRowAction!, indexPath: NSIndexPath!) in
            println("Triggered end action \(action) atIndexPath: \(indexPath)")
            
            //Set the timer to end within CoreData
            self.endTimer(indexPath)
    
            //Create an array containing the indexPath
            var array:Array = [indexPath]
            
            //Refresh the row with animation
            self.timerTable.reloadRowsAtIndexPaths(array, withRowAnimation: UITableViewRowAnimation.Right)
            
            return
        })
        
        endAction.backgroundColor = UIColor(red: 0.945, green: 0.412, blue: 0.000, alpha: 1.00)
        
        var deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete", handler: {
            (action: UITableViewRowAction!, indexPath: NSIndexPath!) in
            println("Triggered delete action \(action) atIndexPath: \(indexPath)")
            
            //Delete the timer
            self.deleteTimer(indexPath)
            
            //Cancel any scheduled alerts with identifier
            self.cancelScheduledAlert(timerItem.objectID.URIRepresentation())
            
            return
        })
        
        deleteAction.backgroundColor = UIColor(red: 0.929, green: 0.000, blue: 0.047, alpha: 1.00)
        
        if timerItem.startedIndicator == 1 {
            return [deleteAction, endAction]
        } else {
            return [deleteAction, editAction]
        }
    }
    
    override func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        stopTimer()
    }
    
    //After any edits have/haven't been made, start the timer back up
    override func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        startTimer()
        
        //If after editing there are no more timers, show a data message
        showHideNoDataMessage()
    }
    
    //Needed to display the editing buttons for the table
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        return
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Create timer if one was not created
        if timer.valid == false {
            startTimer()
        }
        
        // Get the timer for this index
        let timerItem = timers[indexPath.row]
        
        // Check to see if the timer is currently running
        if timerItem.startedIndicator == 1 {
            alertUserForRestart("Timer Currently Running", message: "The timer is currently running, would you want to restart it?", action: "Restart", indexPath: indexPath)
        } else {
            //Kick off the timer
            kickOffTimer(indexPath)
        }
    }
    
    //Used by the timer to refresh the table values
    func runCounter() {
        //Set activeTimers to 0
        activeTimers = 0
        
        //Iterate through timers and get a count of active timers
        for timer in enumerate(timers) {
            activeTimers = activeTimers + timer.element.startedIndicator.integerValue
        }
        
        //Deactivate the NSTimer if there are no currently running ones
        if activeTimers == 0 && timer.valid {
            stopTimer()
        } else {
            timerTable.reloadData()
            println("Active Timers: \(activeTimers)")
            println("timer valid: \(timer.valid)")
            println("Table reloaded")
        }
    }
    
    func showHideNoDataMessage() {
        //Check if there are no timers available
        if timers.count == 0 {
            // Creating a label
            label = UILabel(frame: CGRect(x: 0, y: 10, width: CGRectGetWidth(self.view.bounds), height: 80))
            label.center.x = self.view.center.x
            label.center.y = self.view.center.y - 220
            label.textAlignment = NSTextAlignment.Center
            label.numberOfLines = 2
            label.text = "Tap the + sign above to\n add some timers"
            
            // Creating Arrow Image
            var image = UIImage(named: "CurvedArrow3.png")
            arrow = UIImageView(frame: CGRectMake(100, 150, 50, 50))
            arrow.image = image
            arrow.center.x = self.view.bounds.width - 37
            arrow.center.y = self.view.center.y - 240
            
            // Adding a label as a subview to the view
            self.view.addSubview(label)
            
            // Adding a UIImageView as a subview to the view
            self.view.addSubview(arrow)
        } else {
            label.hidden = true
            arrow.hidden = true
        }
    }
    
    //
    // All methods for controlling interaction with the NSTimer Object
    //

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
    
    //Used to create a timer object
    func startTimer() {
        if timer.valid == false {
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "runCounter", userInfo: nil, repeats: true)
            println("Timer Started")
        }
    }
    
    //Used to invalidate a timer
    func stopTimer() {
        timer.invalidate()
        println("Timer Stopped")
    }
    
    //Functionally starts the timer for the user
    func kickOffTimer(indexPath: NSIndexPath) {
        // Get the timer for this index
        let timerItem = timers[indexPath.row]
        
        var cell:TimerTableViewCell = tableView.cellForRowAtIndexPath(indexPath)! as TimerTableViewCell
        cell.accessoryType = UITableViewCellAccessoryType.None
        
        //Set the label to display the newly updated time
        cell.countdownLabel.text = displayTicker(Int(timerItem.timerSeconds))
        
        //Handle if the titleLabel is to large with the running timer
        if countElements(timerItem.timerName) > 20 {
            cell.titleLabel.text = "\(timerItem.timerName.substringWithRange(Range(start: timerItem.timerName.startIndex,end: advance(timerItem.timerName.startIndex, 20)))).."
        }
        
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
        scheduleLocalAlert(fireDate,timerName: timerItem.timerName, timerID: timerItem.objectID.URIRepresentation())
    }
    
    //Restart timer if one is currently running, but the user wishes to restart it
    func restartTimer(indexPath: NSIndexPath) {
        //Ends an existing timer
        endTimer(indexPath)
        
        //Kicks off a new timer
        kickOffTimer(indexPath)
    }
    
    //Function used to delete the timer from the table and reset the local notifications
    func deleteTimer(indexPath: NSIndexPath) {
        // Find the timer object the user is trying to delete
        let timerToDelete = timers[indexPath.row]
        
        // Delete it from the managedObjectContext
        managedObjectContext?.deleteObject(timerToDelete)
        
        // Refresh the table view to indicate that it's deleted
        fetchTimers()
        
        // Tell the table view to animate out that row
        [timerTable .deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)]
        
        // Save changes
        save()
    }
    
    //Stops a timer if it is currently running
    func endTimer(indexPath: NSIndexPath) {
        let timerToEnd = self.timers[indexPath.row]
        
        //Cancel any alerts if they are scheduled
        self.cancelScheduledAlert(timerToEnd.objectID.URIRepresentation())
        
        //Update in persistent storage
        var managedObject = timerToEnd
        managedObject.setValue(false, forKey: "startedIndicator")
        save()
        
        //Reload timer values into array
        fetchTimers()
    }
    
    //
    // All methods for scheduling/showing/cancelling alerts
    //
    
    //Used to schedule an alert to show up when the timer runs out
    func scheduleLocalAlert(dateFinished: NSDate, timerName: String, timerID: NSURL) {
        var alert:UILocalNotification = UILocalNotification()
        
        alert.fireDate = dateFinished
        alert.timeZone = NSTimeZone.defaultTimeZone()
        alert.repeatInterval = NSCalendarUnit.allZeros
        alert.soundName = UILocalNotificationDefaultSoundName
        alert.alertBody = "Your \"\(timerName)\" timer has gone off"
        alert.applicationIconBadgeNumber++
        
        //For identification of the local notification
        alert.userInfo = ["URI":timerID.absoluteString!]
        
        println("Created timer for \(dateFinished)")
        
        UIApplication.sharedApplication().scheduleLocalNotification(alert)
    }
    
    //Used to cancel scheduled alerts
    func cancelScheduledAlert(timerID: NSURL) {
        var notificationToCancel:UILocalNotification = UILocalNotification()
    
        var scheduledNotifications = UIApplication.sharedApplication().scheduledLocalNotifications.generate()
        
        //Loop through all scheduled notifications until the URI matches the one that is trying to be stopped
        for notification in enumerate(scheduledNotifications) {
            if let uri = notification.element.userInfo! {
                if timerID.absoluteString! == uri["URI"]! as NSString {
                    notificationToCancel = notification.element as UILocalNotification
                }
            }
        }
        
        //Cancel the notification
        UIApplication.sharedApplication().cancelLocalNotification(notificationToCancel)
    }
    
    //Alert the user if they try to select a currently running timer
    func alertUserForRestart(title: String, message: String, action: String, indexPath: NSIndexPath) {
        /* Create alert */
        let alert = UIAlertController(title: title,
            message: message,
            preferredStyle: .Alert)
        
        /* Create action to handle cancel dismissing */
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil)
        
        /* Add cancel action to handle dismissing the alert */
        alert.addAction(cancelAction)
        
        /* Closure to handle the restart */
        let alertHandler = {(action:UIAlertAction!) -> Void in
            self.restartTimer(indexPath)
        }
        
        /* Create additional action */
        let action = UIAlertAction(title: "\(action)", style: UIAlertActionStyle.Default, handler: alertHandler)
        
        /* Add additional action to alert */
        alert.addAction(action)
        
        /* Set off Alert */
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    //
    // All methods for formatting the time values effectively for presentation
    //
    
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
    
    func displayTicker(secondsDefined: Int) -> String{
        var seconds = secondsDefined
        var hours   = seconds / 3600
        var mins    = (seconds % 3600) / 60
        var secs    = seconds % 60
        
        //Format Approriately
        var displayhours:String = trimTime("\(hours)")
        var displaymins:String  = trimTime("\(mins)")
        var displaysecs:String  = trimTime("\(secs)")
        
        var displaytext = "\(displayhours):\(displaymins):\(displaysecs)"
        
        return displaytext
    }
    
    
    
    //
    // All methods to interact with NSManagedObjects (TimersDefined)
    //
    
    //Used to save to Managed Object Context (Updating values)
    func save() {
        var error : NSError?
        if(managedObjectContext!.save(&error) ) {
            println(error?.localizedDescription)
        }
    }

    
    
    //
    // All methods to interact with Segues
    //
    
    //Passes information about the timer being edited/added
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editTimerSegue" {
            var editTimerView = segue.destinationViewController as EditTimerViewController
        
            //Editing action
            if timerEditing == true {
                var timerItem:TimersDefined = timers[timerSelectedRow] as TimersDefined
                editTimerView.timerObjectID  = timerItem.objectID
                editTimerView.timerEditing = true
            }
            
            //Adding action
            if timerEditing == false {
                //Set passing information
                editTimerView.timerEditing = false
            }
            
            //Reset this for future segues
            timerEditing = false

        }
    }
}
