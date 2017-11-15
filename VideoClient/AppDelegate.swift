//
//  AppDelegate.swift
//  VideoClient
//
//  Created by Krishna Picart on 6/6/17.
//  Copyright © 2017 StepwiseDesigns. All rights reserved.
//

import UIKit
import CoreData
@UIApplicationMain


class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if let sourceApplication = options[.sourceApplication] {
            if (String(describing: sourceApplication) == "com.apple.SafariViewService") {
                NotificationCenter.default.post(name: Notification.Name("codeRequest"), object: url)
                return true
            }
        }
        
        return false
    }
    //Preload data
    func preloadData() {
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //preloadData()
       
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
       }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        }
    
    func applicationWillTerminate(_ application: UIApplication) {
        //Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
}



