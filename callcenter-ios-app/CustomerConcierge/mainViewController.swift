//
//  mainViewController.swift
//  CustomerConcierge
//
//  Created by Garrett Rowe on 6/26/18.
//

import Foundation
import UIKit
import AVFoundation
import PushKit
import CallKit
import TwilioVoice
import UserNotifications
import Alamofire

class mainViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var mainWeb: UIWebView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    @objc func cloadPage(_ notification: Notification) {
        loadPage()
    }
    func loadPage() {
        NSLog("Loading Web Content for " + yourPhone)
        let url = URL(string: "https://customerconcierge.mybluemix.net/main?yourPhone=" + yourPhone + "&agentPhone=" + agentPhone + "&industry=" + industry)!
        let urlRequest: URLRequest = URLRequest(url: url)
        self.mainWeb!.loadRequest(urlRequest)
        
        if (industry == "2"){
            let content = UNMutableNotificationContent()
            content.title = "Energy Alert"
            content.body = "Your energy consumption today is greatly above normal.  Visit the PowerCo app for more info and help."
            content.sound = UNNotificationSound.default()
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 20, repeats: false)
            
            let request = UNNotificationRequest(identifier: "TestIdentifier", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

            let parameters: [String: String] = ["yourPhone" : yourPhone]
            Alamofire.request("https://customerconcierge.mybluemix.net/getalert", method: .post, parameters: parameters, encoding: JSONEncoding.default)
                .responseString { response in
                    if (response.result.isSuccess){
                        
                    }
            }
            
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(cloadPage(_:)),name:NSNotification.Name(rawValue: "mainPage"), object: nil)
        
    }
    
    func webView(_ mainWeb: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        switch navigationType {
        case .linkClicked:
            guard let url = request.url else { return true }
            
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
            return false
        default:
            // Handle other navigation types...
            return true
        }
    }
    
    func webViewDidFinishLoad(_ watsonWeb: UIWebView) {
        let scrollableSize = CGSize(width: view.frame.size.width-30, height: mainWeb.scrollView.contentSize.height)
        self.mainWeb?.scrollView.contentSize = scrollableSize
        self.mainWeb?.scrollView.bounces = false
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        mainWeb?.delegate = self
        mainWeb.allowsInlineMediaPlayback = true
        loadPage()
        
        
    }
    
    
}
