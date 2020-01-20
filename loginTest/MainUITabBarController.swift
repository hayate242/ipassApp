//
//  MainUITabBarController.swift
//  iPassTest
//
//  Created by 中山颯 on 2016/09/25.
//  Copyright © 2016年 Tabusalab. All rights reserved.
//

import UIKit

class MainUITabBarController: UITabBarController {

    override func viewDidLoad() {
        //戻るボタンを消す
        self.navigationItem.hidesBackButton = true
        
        //
//        let nav = UINavigationController(rootViewController: MainViewController())
//        self.presentViewController(nav, animated: true, completion: nil)
    }
}
