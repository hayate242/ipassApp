//
//  BLEperipheralCustomCell.swift
//  iPassTest
//
//  Created by 中山颯 on 2016/09/24.
//  Copyright © 2016年 Tabusalab. All rights reserved.
//

import Foundation
import UIKit

class BLEperipheralCustomCell: UITableViewCell {
    

    @IBOutlet weak var peripheralNameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!

    @IBOutlet weak var sendSw: UISwitch!
    @IBAction func changed(sender: UISwitch) {
        
    }

    
}