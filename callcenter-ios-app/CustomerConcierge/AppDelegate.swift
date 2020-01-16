//
//  AppDelegate.swift
//  Twilio Voice with CallKit Quickstart - Swift
//
//  Copyright © 2016 Twilio, Inc. All rights reserved.
//

import UIKit
import TwilioVoice
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    @nonobjc func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject:AnyObject]?) -> Bool {
        UIApplication.shared.isStatusBarHidden = true
        
        return true
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            print("granted: (\(granted)")
        }
        
        NSLog("Twilio Voice Version: %@", TwilioVoice.version())
        self.registerDefaultsFromSettingsBundle()
        return true
    }
    
    
    func registerDefaultsFromSettingsBundle(){
        guard let settingsBundle = Bundle.main.path(forResource: "Settings", ofType: "bundle") else {
            print("Could not locate Settings.bundle")
            return
        }
        
        guard let settings = NSDictionary(contentsOfFile: settingsBundle+"/Root.plist") else {
            print("Could not read Root.plist")
            return
        }
        
        let preferences = settings["PreferenceSpecifiers"] as! NSArray
        var defaultsToRegister = [String: AnyObject]()
        for prefSpecification in preferences {
            if let post = prefSpecification as? [String: AnyObject] {
                guard let key = post["Key"] as? String,
                    let defaultValue = post["DefaultValue"] else {
                        continue
                }
                defaultsToRegister[key] = defaultValue
            }
        }
        UserDefaults.standard.register(defaults: defaultsToRegister)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    func addNotification(title: String, category: String, UI: String, date: Date) {
        
        // Remove Notification
        
        removeNotifcation(UI: UI)
        
        // Create Notification
        // iOS 10 Notification
        
        if #available(iOS 10.0, *) {
            
            let notif = UNMutableNotificationContent()
            
            notif.title = title
            notif.subtitle = "Reminder for \(title)"
            notif.body = "Your Reminder for \(title) set for \(date)"
            notif.sound = UNNotificationSound.default()
            notif.categoryIdentifier = UI
            
            let today = Date()
            
            let interval = date.timeIntervalSince(today as Date)
            
            let notifTrigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            
            let request = UNNotificationRequest(identifier: title, content: notif, trigger: notifTrigger)
            
            UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
                if error != nil {
                    print(error as Any)
                    // completion(Success: false)
                } else {
                    //completion(Sucess: true)
                }
            })
        } else {
            let newNotification:UILocalNotification = UILocalNotification()
            
            newNotification.category = category
            newNotification.userInfo = [ "UUID"  : UI]
            newNotification.alertBody = "Your reminder for \(title)"
            newNotification.fireDate = date
            //notification.repeatInterval = nil
            newNotification.soundName = UILocalNotificationDefaultSoundName
            
            UIApplication.shared.scheduleLocalNotification(newNotification)
            
        }
        
    }
    
    func removeNotifcation(UI: String) {
        
        //Remove Notif
        //iOS 10 Notification
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [UI])
        } else {
            //Remove Notif
            
            let app:UIApplication = UIApplication.shared
            for oneEvent in app.scheduledLocalNotifications! {
                let notification = oneEvent as UILocalNotification
                let userInfoCurrent = notification.userInfo!
                let uuid = userInfoCurrent["UUID"] as! String
                if uuid == UI {
                    //Cancelling local notification
                    app.cancelLocalNotification(notification)
                    break;
                }
            }
        }
        
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

