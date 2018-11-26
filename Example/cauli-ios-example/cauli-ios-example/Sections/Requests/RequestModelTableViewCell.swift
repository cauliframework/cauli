//
//  RequestModelTableViewCell.swift
//  cauli-ios-example
//
//  Created by Cornelius Horstmann on 17.11.18.
//  Copyright © 2018 brototyp.de. All rights reserved.
//

import UIKit

class RequestModelTableViewCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
