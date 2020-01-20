//
//  BLECustomCell.swift
//  iPassTest
//
//  Created by 中山颯 on 2016/09/24.
//  Copyright © 2016年 Tabusalab. All rights reserved.
//

import UIKit

class BLECustomCell: UITableViewCell {
    
    
    
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var sw: UISwitch!
    @IBAction func changed(sender: UISwitch) {
        
//        var hoge = sender.superview
//        while(hoge!.isKindOfClass(BLECustomCell) == false) {
//            hoge = hoge!.superview
//        }
//        let cell = hoge as! BLECustomCell
//        // touchIndexは選択したセルが何番目かを記録しておくプロパティ
//        //        touchIndex = self.tableView.indexPathForCell(cell)
        
//        var btn = sender
//        var cell = btn.superview?.superview as! UITableViewCell
//        var row = bleTableView.indexPathForCell(cell)?.row
//        
//        // 行数を表示
//        print(row)
        print(sw.on)
    }

    @IBOutlet weak var BLEstatus: UILabel!
    
}
