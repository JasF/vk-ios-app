//
//  AppDelegate.swift
//  MessageGroups
//
//  Created by Tainter, Aaron on 8/17/16.
//  Copyright © 2016 Ebay Inc. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import HockeySDK
import CocoaLumberjack

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}
extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }
}
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    @objc dynamic var pythonBridge: PythonBridge?
    @objc dynamic var screensManager: ScreensManager?
    @objc dynamic var pythonManager: PythonManager?
    @objc dynamic var notificationsManager: NotificationsManager?
    @objc dynamic var modules: Modules?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        DDLog.add(DDTTYLogger.sharedInstance) // TTY = Xcode console
        switch UIApplication.shared.releaseMode() {
        case .adHoc, .dev, .enterprise, .sim:
            DDLog.add(DDASLLogger.sharedInstance) // TTY = Xcode console
            if let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first {
                let path = docsDir + "/logs"
                do {
                    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                } catch {}
                let logsFileManager = DDLogFileManagerDefault(logsDirectory: path)
                let fileLogger: DDFileLogger = DDFileLogger(logFileManager: logsFileManager) // File Logger
                fileLogger.rollingFrequency = TimeInterval(60*60*24)  // 24 hours
                fileLogger.logFileManager.maximumNumberOfLogFiles = 7
                DDLog.add(fileLogger)
            }
            break
        default: break;
        }
        
        // Override point for customization after application launch.
        BITHockeyManager.shared().configure(withIdentifier: "b3125c1736c24cafbd158dd12bbf4af7")
        BITHockeyManager.shared().start()
        self.pythonManager?.startupPython()
        self.screensManager?.createWindowIfNeeded()
        
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.notificationsManager?.didRegisterForRemoteNotifications(withDeviceToken: deviceToken.hexEncodedString())
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        self.notificationsManager?.didFailToRegisterForRemoteNotificationsWithError(error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        self.notificationsManager?.didReceiveRemoteNotification(userInfo)
        completionHandler(.newData);
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if let events = modules?.systemEvents {
            dispatch_python {
                events.applicationWillResignActive()
            }
        }
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        if let events = modules?.systemEvents {
            dispatch_python {
                events.applicationDidEnterBackground()
            }
        }
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if let events = modules?.systemEvents {
            dispatch_python {
                events.applicationWillEnterForeground()
            }
        }
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        if let events = modules?.systemEvents {
            dispatch_python {
                events.applicationDidBecomeActive()
            }
        }
        FBSDKAppEvents.activateApp()
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        if let events = modules?.systemEvents {
            dispatch_python {
                events.applicationWillTerminate()
            }
        }
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        VKSdk.processOpen(url, fromApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String)
        return true;
    }
    /*
    - (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    [VKSdk processOpenURL:url fromApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]];
    return YES;
    }
    */

}

