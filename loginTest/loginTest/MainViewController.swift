//
//  MainViewController.swift
//  loginTest
//
//  Created by 中山颯 on 2016/09/17.
//  Copyright © 2016年 Tabusalab. All rights reserved.
//

import UIKit
import Foundation

class MainViewController: UIViewController {
    

    @IBAction func logoutAction(sender: UIButton) {
        let appDomain = NSBundle.mainBundle().bundleIdentifier
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName(appDomain!)
        
        self.performSegueWithIdentifier("goto_login", sender: self)
    }
    
//    override func viewDidLoad() {
//        navigationItem.title = "画面1"
//    }
    @IBOutlet weak var timeLabel: UILabel!
    let clock = Clock()
    var timer: NSTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //戻るボタンを消す
        self.navigationItem.hidesBackButton = true
        
        self.title = "Home"
        
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateTimeLabel", userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        updateTimeLabel()
    }
    
    func updateTimeLabel() {
        let formatter = NSDateFormatter()
        formatter.timeStyle = .MediumStyle
        timeLabel.text = formatter.stringFromDate(clock.currentTime)
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.All
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        if let timer = self.timer {
            timer.invalidate()
        }
    }

    
    
}
