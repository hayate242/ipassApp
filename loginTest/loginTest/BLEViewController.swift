//
//  BLEViewController.swift
//  iPassTest
//
//  Created by 中山颯 on 2016/09/24.
//  Copyright © 2016年 Tabusalab. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

/**
 1.ペリフェラル(機器)を探し、リストアップ
 2.接続する
 3.サービスの探索
 4.サービスに接続
 5.キャラクタリスティック(データ?)の探索
 6.キャラクタリスティックの受取
 */

class BLEViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // AppDelegateのインスタンスを取得
    let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    //BLE
    var Timer:NSTimer!
    /** BLE機器のUUID配列 */
    var myUUIDs:NSMutableArray=NSMutableArray()
    /** BLE機器の名前配列 */
    var myNames:NSMutableArray=NSMutableArray()
    /** BLE機器のペリフェラル配列 */
//    var myPeripheral:NSMutableArray=NSMutableArray()
    /** 管理人:セントラルマネージャ */
    var myCentralManager:CBCentralManager!
    /** サービスのUUID配列 */
    //var myServiceUUIDs: NSMutableArray = NSMutableArray()
    /** サービス配列 */
    //var myService: NSMutableArray = NSMutableArray()
    /** ターゲットペリフェラル(複数のペリフェラルの中の内の一つ) */
    var myTargetPeripheral: CBPeripheral!
    
    
    
    var firstSend: Bool = true
    var newPeripheral: Bool = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //配列リセット
        myNames = NSMutableArray()
        myUUIDs = NSMutableArray()
        appDelegate.myPeripheral = NSMutableArray()
        
        //CoreBluetoothを初期化及び始動
//        myCentralManager=CBCentralManager(delegate: self, queue: nil,options: nil)
        

    }
    //**  */
    func centralManagerDidUpdateState(central: CBCentralManager) {
        print("state \(central.state)");
        switch (central.state) {
        case .PoweredOff:
            print("Bluetoothの電源がOff")
        case .PoweredOn:
            print("Bluetoothの電源はOn")
            // BLEデバイスの検出を開始.
            myCentralManager.scanForPeripheralsWithServices(nil, options: nil)
        case .Resetting:
            print("レスティング状態")
        case .Unauthorized:
            print("非認証状態")
        case .Unknown:
            print("不明")
        case .Unsupported:
            print("非対応")
        }
    }
    /**
     BLEデバイスが検出された際に呼び出される.
     */
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        print("----------------")
        print("pheripheral.name: \(peripheral.name)")
        print("advertisementData:\(advertisementData)")
        print("RSSI: \(RSSI)")
        print("peripheral.identifier.UUIDString: \(peripheral.identifier.UUIDString)")
        print("----------------")
        
        var name: NSString? = advertisementData["kCBAdvDataLocalName"] as? NSString
        if (name == nil) {
            name = "no name";
        }
        
        
        
 
        if(peripheral.name != nil && peripheral.name!.containsString("iPass-")){
            myNames.addObject(name!)
            appDelegate.myPeripheral.addObject(peripheral)
            myUUIDs.addObject(peripheral.identifier.UUIDString)
            //リストの最後のペリフェラルにつなげる(片っ端から)
//            myCentralManager.connectPeripheral(self.appDelegate.myPeripheralmyPeripheral.lastObject as! CBPeripheral, options: nil)
            
            //新しくperipheralを見つけたら
            newPeripheral = true
        }
    }
    /**
     Peripheralに接続
     */
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral){
        print("connect \(peripheral.name)")
        
        Timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector:"checkRSSI", userInfo: nil, repeats: true)
        //接続されているperipherarlの名前を表示する
        Timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector:"getPeripheralName", userInfo: nil, repeats: true)
        searchService(peripheral)
    }
    
    /**
     Peripheralに接続失敗した際
     */
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?){
        print("not connnect")
        
    }
    /**
     サービス見つけたら
     */
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        
        print("didDiscoverServices \(peripheral.name)")
        
        let myService:NSMutableArray=NSMutableArray()
        let myServiceUUIDs:NSMutableArray=NSMutableArray()
        
        for service in peripheral.services! {
            myService.addObject(service)
            myServiceUUIDs.addObject(service.UUID)
            print("P: \(peripheral.name) - Discovered service S:'\(service.UUID)'")
        }
        
        //キャラクタリスティックの探索
        if(myService.count > 0 ){
            peripheral.discoverCharacteristics(nil, forService: myService[0] as! CBService)
        }
    }
    
    /**
     Serviceの検索
     */
    func searchService(peripheral:CBPeripheral){
        
        print("searchService")
//        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    /**
     キャラクタリスティック見っけたら
     */
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService,
                    error: NSError?) {
        print("didDiscoverCharacteristicsForService")
        
        var myCharacteristicsUuids: NSMutableArray = NSMutableArray()
        
        for characteristics in service.characteristics! {
            myCharacteristicsUuids.addObject(characteristics.UUID)
            print(characteristics.UUID.description)
            
            peripheral.setNotifyValue(true, forCharacteristic: characteristics)
            
            let data: NSData! = "I can see you".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:true)
            peripheral.writeValue(data, forCharacteristic: characteristics, type: CBCharacteristicWriteType.WithResponse)
        }
        
    }
    
    
    
    /**
     read用
     */
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    {
        print("******\(characteristic.value)******")
        
        print(characteristic.value)
        
        /*  peripheralから受け取ったデータをdataFromPに入れる */
        let temp : NSData = characteristic.value!
        if let dataFromP = NSString(data:temp, encoding:NSUTF8StringEncoding) {
            print("result: '\(dataFromP)'")
        }
        
        
    }
    
    
    /**
     Write
     */
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    {
        //Door用
        //watchIDを書き込む RSSI > -30 初めて送る peripheral名にDoorと含まれる
        //        if peripheral.RSSI as! Int > -30 && firstSend == true && peripheral.name!.containsString("Door"){
        if firstSend == true {
            let data = "1234567true".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:true)
            
            
            peripheral.writeValue(data!, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
            
            if let error = error {
                print("Write失敗...error: \(error)")
                return
            }
            
            print("Write成功！")
            firstSend = false
        }
        
        if newPeripheral {
            let data = "tellMeSta".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:true)
            peripheral.writeValue(data!, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
            print("I sent tellMe")
            newPeripheral = false
        }
        
        
        
        
        print("Write Success to \(peripheral.name)")
        
        
    }
    
    
    
    func checkRSSI(){
        for(var i:Int = 0; i < appDelegate.myPeripheral.count;i++){
            //            print(myPeripheral[i].namePrefix)
            //            print(myPeripheral)
            appDelegate.myPeripheral[i].readRSSI()
        }
    }
    func getPeripheralName(){
        for(var i:Int = 0; i < appDelegate.myPeripheral.count;i++){
            print(i)
            print(appDelegate.myPeripheral[i].name!)
        }
        //        print(myPeripheral)
        
    }
    
    func peripheralDidUpdateRSSI(peripheral: CBPeripheral, error: NSError?) {
        print("\(peripheral.name):\(peripheral.RSSI)")
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
//        return appDelegate.myPeripheral.count  //辞書の数だけ繰り返す
        return 5
    }
    
    var i: Int = 0
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("BLECell", forIndexPath: indexPath) as! BLECustomCell
        
        //
//        var peripheral : String = appDelegate.myPeripheral[i].name! as! String
//        cell.deviceNameLabel.text = ( peripheral )
//        
//        if peripheral.containsString("Door") {
//            cell.typeLabel.text = "Door"
//        }else if peripheral.containsString("fan") {
//            cell.typeLabel.text = "扇風機"
//        }else {
//            cell.typeLabel.text = "???"
//        }
//        
//        i++
        cell.deviceNameLabel.text = "Hello"
        cell.typeLabel.text = "???"
        cell.sw.on = false
        return cell
    }
    
    
}