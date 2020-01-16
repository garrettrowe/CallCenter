//
//  UITabBarController.swift
//  CustomerConcierge
//
//  Created by Garrett Rowe on 6/26/18.
//  Copyright © 2018 Twilio, Inc. All rights reserved.
//

import Foundation
import UIKit


class TabBarController: UITabBarController{
    
    
    
    override func viewDidLoad() {
        NSLog("Loading TabBar")
        yourPhone = defaults.string(forKey: "yourPhone")!.trim()
        agentPhone = defaults.string(forKey: "agentPhone")!.trim()
        industry = defaults.string(forKey: "subIndustry")!.trim()

        for viewController in self.viewControllers! {
            _ = viewController.view
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
        super.viewDidLoad()
        
       
        
    }
    
    func defaultsChanged(notification:NSNotification){
        if let newDefaults = notification.object as? UserDefaults {
            NSLog("Found New Settings!")
            yourPhone = newDefaults.string(forKey: "yourPhone")!.trim()
            agentPhone = newDefaults.string(forKey: "agentPhone")!.trim()
            industry = newDefaults.string(forKey: "subIndustry")!.trim()
            NotificationCenter.default.post(name: Notification.Name(rawValue: "helpPage"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "mainPage"), object: nil)


        }
    }

}
