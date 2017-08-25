//
//  SwitchCollectionViewCell.swift
//  TestApplication
//
//  Created by Pascal Stüdlein on 22.07.17.
//  Copyright © 2017 HTW Berlin. All rights reserved.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var `switch`: UISwitch!
    var switchTriggered: ((Bool)->())?
    
    @IBAction func changed(_ sender: Any) {
        switchTriggered?(`switch`.isOn)
    }
    
}
