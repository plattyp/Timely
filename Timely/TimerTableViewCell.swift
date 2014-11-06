//
//  TimerTableViewCell.swift
//  Timely
//
//  Created by Andrew Platkin on 10/28/14.
//  Copyright (c) 2014 PlattypusLabs. All rights reserved.
//

import UIKit

class TimerTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var countdownLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
