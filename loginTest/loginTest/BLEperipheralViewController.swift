//
//  BLEperipheralViewController.swift
//  iPassTest
//
//  Created by 中山颯 on 2016/09/24.
//  Copyright © 2016年 Tabusalab. All rights reserved.
//

import UIKit
import Foundation

class BLEperipheralViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // AppDelegateのインスタンスを取得
    let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
//        return appDelegate.myPeripheral.count  //辞書の数だけ繰り返す
        return 5
    }
    
    var cntCell: Int = 0
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let BLEperipheralCell = tableView.dequeueReusableCellWithIdentifier("BLEPeripheralCell", forIndexPath: indexPath) as! BLEperipheralCustomCell
//
//        var peripheral : String = appDelegate.myPeripheral[cntCell].name! as! String
//        BLEperipheralCell.peripheralNameLabel.text = ( peripheral )
//        
//        if peripheral.containsString("Door") {
//            BLEperipheralCell.typeLabel.text = "Door"
//        }else if peripheral.containsString("fan") {
//            BLEperipheralCell.typeLabel.text = "扇風機"
//        }else {
//            BLEperipheralCell.typeLabel.text = "???"
//        }
//        
//        
//        return BLEperipheralCell
        BLEperipheralCell.peripheralNameLabel.text = "Name"
        BLEperipheralCell.typeLabel.text = "Door"
        BLEperipheralCell.sendSw.on = true
//        let onOffControl = UISwitch()
//        onOffControl.on = true
//        onOffControl.addTarget(self, action: "onSwitch:", forControlEvents: UIControlEvents.ValueChanged)
//        BLEperipheralCell.accessoryView = UIView(frame: onOffControl.frame)
//        BLEperipheralCell.accessoryView?.addSubview(onOffControl)
        return BLEperipheralCell
    }
}
