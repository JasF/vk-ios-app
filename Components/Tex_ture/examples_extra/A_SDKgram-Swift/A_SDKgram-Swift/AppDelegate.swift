//
//  AppDelegate.swift
//  A_SDKgram-Swift
//
//  Created by Calum Harris on 06/01/2017.
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//
//  THE SOFTWARE IS PROVIDED "A_S IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit
import Async_DisplayKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

		// UIKit Home Feed viewController & navController

		let UIKitNavController = UINavigationController(rootViewController: PhotoFeedTableViewController())
		UIKitNavController.tabBarItem.title = "UIKit"

		// A_SDK Home Feed viewController & navController

		let A_SDKNavController = UINavigationController(rootViewController: PhotoFeedTableNodeController())
		A_SDKNavController.tabBarItem.title = "A_SDK"

		// UITabBarController

		let tabBarController = UITabBarController()
		tabBarController.viewControllers = [UIKitNavController, A_SDKNavController]
		tabBarController.selectedIndex = 1
		tabBarController.tabBar.tintColor = UIColor.mainBarTintColor()

		// Nav Bar appearance

		UINavigationBar.appearance().barTintColor = UIColor.mainBarTintColor()

		// UIWindow

		window = UIWindow()
		window?.backgroundColor = .white
		window?.rootViewController = tabBarController
		window?.makeKeyAndVisible()

		return true
	}

}
