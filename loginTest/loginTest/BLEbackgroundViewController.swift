//
//  BLEbackground.swift
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
class BLEbackgroundViewController: UIViewController ,CBCentralManagerDelegate,CBPeripheralDelegate{
    var Timer:NSTimer!
    /** BLE機器のUUID配列 */
    var myUUIDs:NSMutableArray=NSMutableArray()
    /** BLE機器の名前配列 */
    var myNames:NSMutableArray=NSMutableArray()
    /** BLE機器のペリフェラル配列 */
    var myPeripheral:NSMutableArray=NSMutableArray()
    
    
    /** 管理人:セントラルマネージャ */
    var myCentralManager:CBCentralManager!
    /** サービスのUUID配列 */
    //var myServiceUUIDs: NSMutableArray = NSMutableArray()
    /** サービス配列 */
    //var myService: NSMutableArray = NSMutableArray()
    /** ターゲットペリフェラル(複数のペリフェラルの中の内の一つ) */
    var myService: CBService!
    var myTargetPeripheral: CBPeripheral!
    
    var myCharacteristics: NSMutableArray = NSMutableArray()
    var myTargetCharacteristics: CBCharacteristic!
    
    var firstSend: Bool = true
   
    
    //扇風機を動かす
    var fanFlag: Bool = false
    var fanStatus: Bool = false
    

    //サーバーから受け取ってtableに表示する配列
    var tableSource: Array<NSDictionary>!
    
    @IBOutlet weak var bleTableView: UITableView!
    
    //書き込むperipheralのターゲット
    var touchRequestTarget: Int = -1
    //peripheralから受け取ったステータス
    var pStatus = [ String : String ]()
    
    // AppDelegateのインスタンスを取得
    let appDelegate: AppDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //配列リセット
        myNames = NSMutableArray()
        myUUIDs = NSMutableArray()
        myPeripheral = NSMutableArray()
        
        //CoreBluetoothを初期化及び始動(バックグラウンドに対応)
//        let options: Dictionary = [
//            CBCentralManagerOptionRestoreIdentifierKey: "myKey"
//        ]
//        myCentralManager=CBCentralManager(delegate: self, queue: nil,options: options)
        
        //CoreBluetoothを初期化及び始動
        myCentralManager=CBCentralManager(delegate: self, queue: nil,options: nil)
        
        
    }
    
    
    
    override func viewWillAppear(animated: Bool) {
        //配列リセット
//        myNames = NSMutableArray()
//        myUUIDs = NSMutableArray()
//        myPeripheral = NSMutableArray()

        // Do any additional setup after loading the view, typically from a nib.
        let username:String = appDelegate.myWatchID
        
        var post:NSString = "WatchID=\(username)"
        
        NSLog("PostData: %@",post);
        
        var url:NSURL = NSURL(string: "http://tabuken.jp/ipass/nakayama/get_MyMonoIDiOS.php")!
        
        var postData:NSData = post.dataUsingEncoding(NSASCIIStringEncoding)!
        
        var postLength:NSString = String( postData.length )
        
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: url)
        print(postData)
        request.HTTPMethod = "POST"
        request.HTTPBody = postData
        request.setValue(postLength as String, forHTTPHeaderField: "Content-Length")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        
        var reponseError: NSError?
        var response: NSURLResponse?
        
        var urlData: NSData?
        do{
            try urlData = NSURLConnection.sendSynchronousRequest(request, returningResponse:&response)
        } catch let error as NSError {
            print("Error")
        }
        
        if ( urlData != nil ) {
            let res = response as! NSHTTPURLResponse!;
            
            NSLog("Response code: %ld", res.statusCode);
            
            if (res.statusCode >= 200 && res.statusCode < 300)
            {
                var responseData:NSString  = NSString(data:urlData!, encoding:NSUTF8StringEncoding)!
                
                NSLog("Response ==> %@", responseData);
                
                var error: NSError?
                
                var jsonData:NSDictionary?
                jsonData = NSDictionary()
                do{
                    try jsonData = NSJSONSerialization.JSONObjectWithData(urlData!, options:NSJSONReadingOptions.MutableContainers) as? NSDictionary
                } catch let error as NSError {
                    print("Error")
                }
                
                var AllData:NSArray = jsonData!.valueForKey("data") as! NSArray
                self.tableSource = AllData as! Array
                
                print(AllData)
                //セルの数を入れる
//                cntCell = tableSource.count
            }
        }else{
            print("fuck!I don't get any data")
        }
        
//        //テーブル書き直し
        i = 0
        print("i = 0")
        self.bleTableView.reloadData()
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /*
     接続先のPeripheralを設定
     */
    func setPeripheral(target: CBPeripheral) {
        
        self.myTargetPeripheral = target
        print("target")
        print(target)
        
    }
    /*
     CentralManagerを設定
     */
    func setCentralManager(manager: CBCentralManager) {
        
        self.myCentralManager = manager
        print(manager)
    }
    
    /*
     Serviceの検索
     */
    func searchService(){
        
        print("searchService")
        self.myTargetPeripheral.delegate = self
        self.myTargetPeripheral.discoverServices(nil)
    }
    
    /*
     CentralManagerを設定
     */
    func setService(service: CBService) {
        
        self.myService = service
        print(service)
    }
    /*
     Charactaristicsの検索
     */
    func searchCharacteristics(){
        
        print("searchService")
        self.myTargetPeripheral.delegate = self
        self.myTargetPeripheral.discoverCharacteristics(nil, forService: self.myService)
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
        
        
        
        //iPassと含まれたら
        if(peripheral.name != nil && peripheral.name!.containsString("iPass-")){
            myNames.addObject(name!)
            myPeripheral.addObject(peripheral)
            myUUIDs.addObject(peripheral.identifier.UUIDString)
            //リストの最後のペリフェラルにつなげる(片っ端から)
            myCentralManager.connectPeripheral(self.myPeripheral.lastObject as! CBPeripheral, options: nil)
            firstSend = true
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
        
        print("setPeripheral")
        self.setPeripheral(peripheral)
        self.setCentralManager(central)
        self.searchService()
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
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    /**
     キャラクタリスティック見っけたら
     */
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService,
                    error: NSError?) {
        print("didDiscoverCharacteristicsForService")
        
//        self.myTargetPeripheral = peripheral
        
        var myCharacteristicsUuids: NSMutableArray = NSMutableArray()
        
        for characteristics in service.characteristics! {
            myCharacteristicsUuids.addObject(characteristics.UUID)
//            print(characteristics.UUID.description)
            myCharacteristics.addObject(characteristics)
            
            
            peripheral.setNotifyValue(true, forCharacteristic: characteristics)
            
            let data: NSData! = "I can see you".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:true)
            peripheral.writeValue(data, forCharacteristic: characteristics, type: CBCharacteristicWriteType.WithResponse)
        }
        //テーブル書き直し
        i = 0
        print("i = 0")
        self.bleTableView.reloadData()
        
    }
    
    
    
    /**
     read用
     */
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    {
//        print("******\(characteristic.value)******")
        
//        print(characteristic.value)
        
        /*  peripheralから受け取ったデータをdataFromPに入れる */
        let temp : NSData = characteristic.value!
        if let dataFromP = NSString(data:temp, encoding:NSUTF8StringEncoding) {
            print("result: '\(dataFromP)'")
            
//            pStatus[] = 
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
            let data = "tellMeSta".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:true)
            
            
            peripheral.writeValue(data!, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
            print(peripheral)
            if let error = error {
                print("Write失敗...error: \(error)")
                return
            }
            
            print("Write成功！")
            firstSend = false
        }
        
        print("Write Success to \(peripheral.name)")
        
        
    }
    
    func checkRSSI(){
        for(var i:Int = 0; i < myPeripheral.count;i++){
            
//            print(myPeripheral)
            print("myPeripheral.readRSSI")
            print(myPeripheral[i].readRSSI())
        }
    }
    func getPeripheralName(){
        for(var i:Int = 0; i < myPeripheral.count;i++){
//            print(i)
//            print(myPeripheral[i].name!)
//            print("myPeripheral = ")
//            print(myPeripheral)
        }
        
    }
    
    func peripheralDidUpdateRSSI(peripheral: CBPeripheral, error: NSError?) {
        print("\(peripheral.name):\(peripheral.RSSI)")
        
        //もし接続されているperipheralがdoorでRSSIの値が-50より大きければ
        if peripheral.name!.containsString("iPass-Door") && peripheral.RSSI?.intValue > -50 {
            
            //targetDoor
            var targetD: Int = 0
            for(var i:Int = 0; i < myPeripheral.count;i++){
                //myTargetCharacteristicsのためにDoorのcharacteristicが入っているindexを取り出す
                if myPeripheral[i] as! NSObject == peripheral {
                    targetD = i
                }
            }
            //characteristicターゲット
            myTargetCharacteristics = myCharacteristics[targetD] as! CBCharacteristic
            //pheripheralターゲット
            self.myTargetPeripheral = myPeripheral[targetD] as! CBPeripheral
            
            //ターゲットがあるなら送る
            if(self.myTargetCharacteristics != nil){
                print("exist myTargetCharacteristics")
                
                //データ更新通知の受け取りを開始する
                myTargetPeripheral.setNotifyValue(true, forCharacteristic: myTargetCharacteristics)
                
                let data: NSData! = "1234567true".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:true)
                //        let data: NSData! = s.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:true)
                
                //データ書き込みを開始する
                self.myTargetPeripheral.writeValue(data, forCharacteristic: myTargetCharacteristics, type: CBCharacteristicWriteType.WithResponse)
            } else {
                print("AutoRSSI myTargetCharacteristicsはnil")
            }
        }
    }
    

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        
        if myPeripheral.count > 0 {
            return myPeripheral.count  //辞書の数だけ繰り返す
        }else {
            return 1
        }
        
//        return tableSource.count  //辞書の数だけ繰り返す
//        return 2
    }
    
    var i: Int = 0
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("BLECell", forIndexPath: indexPath) as! BLECustomCell
        if myPeripheral.count > 0 {
            var peripheral : String? = myPeripheral[i].name! as! String
            print(peripheral)
            peripheral = peripheral!.substringFromIndex(peripheral!.startIndex.advancedBy(6))
            cell.deviceNameLabel?.text =  peripheral!
         
            cell.deviceNameLabel?.textColor = UIColor.brownColor()
            
            if peripheral!.containsString("Door") {
                cell.typeLabel.text = "Door"
            }else if peripheral!.containsString("fan") {
                cell.typeLabel.text = "扇風機"
            }else {
                cell.typeLabel.text = "???"
            }
            
            //接続状態を確認
            var st: Int = myPeripheral[i].valueForKeyPath("state") as! Int
            if st == 2 {
                cell.BLEstatus.text = "接続済"
            }else if st == 0{
                cell.BLEstatus.text = "未接続"
            }
            
            i++
            if i == myPeripheral.count {
                i = 0
            }
            //Switch関係
            cell.sw.addTarget(self, action: #selector(BLEbackgroundViewController.hundleSwitch(_:)), forControlEvents: UIControlEvents.ValueChanged)
            
//            if(){
//                
//            }
            cell.sw.on = false
            
        } else {
            cell.deviceNameLabel.text = "なし"
            cell.typeLabel.text = "???"
            cell.sw.on = false
            cell.BLEstatus.text = "未接続"
        }

        
        print("BLEtable"+String(i))
 
        return cell
    }
    func hundleSwitch(sender: UISwitch) {
        print("Switch!")
        var hoge = sender.superview
        while(hoge!.isKindOfClass(BLECustomCell) == false) {
            hoge = hoge!.superview
        }
        let cell = hoge as! BLECustomCell
        // touchIndexは選択したセルが何番目かを記録しておくプロパティ
        var touchIndex = self.bleTableView.indexPathForCell(cell)
//        print(touchIndex)
        //タッチしたボタンのcell番号を返す
        print(touchIndex?.row)
        touchRequestTarget = (touchIndex?.row)! as! Int
        
        //
//        self.setService(self.myService[touchIndex?.row] as! CBService)
//        self.searchCharacteristics()
        
        //characteristicターゲット
        myTargetCharacteristics = myCharacteristics[touchRequestTarget] as! CBCharacteristic
//        print("mytargetchar")
//        print(myTargetCharacteristics)
        
        //pheripheralターゲット
        self.myTargetPeripheral = myPeripheral[touchRequestTarget] as! CBPeripheral
//        myCentralManager.connectPeripheral(self.myTargetPeripheral, options: nil)
        
        
        print("state")
//        print(myPeripheral[BLErequestTarget].valueForKeyPath("state"))
        var st: Int = myPeripheral[touchRequestTarget].valueForKeyPath("state") as! Int
        print(st)
        print(cell.sw.on)
        
        //スイッチが押された時にMyWatchID+true/falseを送る
        var s: String
        if cell.sw.on == true {
            s = appDelegate.myWatchID+"true"
        }else if cell.sw.on == false {
            s = appDelegate.myWatchID+"false"
        }
        
        //ターゲットがあるなら送る
        if(self.myTargetCharacteristics != nil){
            //データ更新通知の受け取りを開始する
            myTargetPeripheral.setNotifyValue(true, forCharacteristic: myTargetCharacteristics)
            print("hahahaha")
            let data: NSData! = "hello".dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:true)
            //        let data: NSData! = s.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion:true)
            
            //データ書き込みを開始する
            self.myTargetPeripheral.writeValue(data, forCharacteristic: myTargetCharacteristics, type: CBCharacteristicWriteType.WithResponse)
        } else {
            print("myTargetCharacteristicsはnil")
        }
        
        print(myPeripheral)
        print(myTargetPeripheral)
        
    }
    
    
}

