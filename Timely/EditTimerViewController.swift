//
//  EditTimerViewController.swift
//  Timely
//
//  Created by Andrew Platkin on 11/16/14.
//  Copyright (c) 2014 PlattypusLabs. All rights reserved.
//

import UIKit
import CoreData

class EditTimerViewController: UIViewController, UITextFieldDelegate {

    lazy var managedObjectContext : NSManagedObjectContext? = {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        if let managedObjectContext = appDelegate.managedObjectContext {
            return managedObjectContext
        }
        else {
            return nil
        }
    }()
    
    @IBOutlet weak var titleInput: UITextField!
    @IBOutlet weak var timerInput: UIDatePicker!
    @IBOutlet weak var editTimerButton: UIButton!
    
    //For passing variable values through the Segue
    var timerObjectID  = NSManagedObjectID()
    var timerEditing = false
    var timers  = [TimersDefined]()
    
    @IBAction func addTimerButton(sender: AnyObject) {
        
        if timerEditing == true {
            //Leverage existing instance that needs to be modified
            var managedObject = timers[0]
            
            //Update in persistent storage
            managedObject.setValue(titleInput.text, forKey: "timerName")
            managedObject.setValue(timerInput.countDownDuration, forKey: "timerSeconds")
            
            //Save
            save()
        } else {
            //Create instance
            TimersDefined.createInManagedObjectContext(self.managedObjectContext!, name: titleInput.text, seconds: Int(timerInput.countDownDuration))
            
            //Save
            save()
        }
        //Tells the tableView to hide navigation
        somethingAdded = true
        
        //Invalidate previous timer
        timer.invalidate()
        
        //Forward to the list of Timers
        self.performSegueWithIdentifier("backToTimerView", sender: self)
    }
    
    @IBAction func cancelButton(sender: AnyObject) {
        //Forward to the list of Timers
        self.performSegueWithIdentifier("backToTimerView", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleInput.delegate = self
    
        if timerEditing == true {
            //Search for the object being edited
            fetchTimers()
            
            titleInput.text = timers[0].timerName
            timerInput.countDownDuration = NSTimeInterval(timers[0].timerSeconds)
            editTimerButton.setTitle("Update Timer", forState: .Normal)
            self.title = "Edit Timer"
        }
        
        if timerEditing == false {
            titleInput.text == ""
            timerInput.countDownDuration = NSTimeInterval(0)
            editTimerButton.setTitle("Create Timer", forState: .Normal)
            self.title = "Add Timer"
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Used to retrieve the latest from TimersDefined and Insert the results into the timers array
    func fetchTimers() -> Bool {
        let fetchRequest = NSFetchRequest(entityName: "TimersDefined")
        
        fetchRequest.predicate = NSPredicate(format: "self == %@", timerObjectID)
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [TimersDefined] {
            timers = fetchResults
        }
        return true
    }
    
    func save() {
        var error : NSError?
        if(managedObjectContext!.save(&error) ) {
            println(error?.localizedDescription)
        }
    }
    
    //Hide on keyboard return
    func textFieldShouldReturn(textField: UITextField!) -> Bool // called when 'return' key pressed. return NO to ignore.
    {
        self.view.endEditing(true)
        return true;
    }
    
    //Hide on external touches outside the input
    override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!) {
        self.view.endEditing(true)
    }


}
