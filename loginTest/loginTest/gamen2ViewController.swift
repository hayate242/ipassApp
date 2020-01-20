//
//  gamen2ViewController.swift
//  loginTest
//
//  Created by 中山颯 on 2016/09/20.
//  Copyright © 2016年 Tabusalab. All rights reserved.
//

import Foundation
import UIKit

class gamen2ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var historyTableView: UITableView!
    var tableSource: Array<NSDictionary>!
    var cntCell:Int = 0
    
    //Historyを表示
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let gamen2Cell = tableView.dequeueReusableCellWithIdentifier("myCell", forIndexPath: indexPath) as! gamen2CustomCell
        var temp:NSDictionary = tableSource[cntCell] as! NSDictionary
        cntCell += 1
        gamen2Cell.nameLabel.text = (temp.valueForKey("MonoID") as! String)
        gamen2Cell.dateTimeLabel.text = (temp.valueForKey("dateTime") as! String)
        
        let statusHistory: String = (temp.valueForKey("status") as! String)
        if statusHistory == "0" {
            gamen2Cell.statusLabel.text = "OFF"
        }
        else {
            gamen2Cell.statusLabel.text = "ON"
        }
        
        
        
//        let cell = UITableViewCell(style: .Default, reuseIdentifier: "myCell")
//        cell.textLabel?.text = "hahaha"
        return gamen2Cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return tableSource.count  //辞書の数だけ繰り返す
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        historyTableView.delegate = self
        historyTableView.dataSource = self
        // Do any additional setup after loading the view, typically from a nib.
        var username:String = "1234567";
        
        var post:NSString = "WatchID=\(username)"
        
        NSLog("PostData: %@",post);
        
        var url:NSURL = NSURL(string: "http://tabuken.jp/ipass/nakayama/get_HistoryiOS.php")!
        
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
            }
        }else{
            print("fuck!I don't get any data")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}