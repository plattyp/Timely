//
//  NavigationController.swift
//  Timely
//
//  Created by Andrew Platkin on 11/22/14.
//  Copyright (c) 2014 PlattypusLabs. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.tintColor = UIColor.whiteColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
