//
// Copyright (c) 2016 eBay Software Foundation
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import UIKit

//MARK: ModalAlertUtilities class
/**
 Custom alerts for NMessenger
 */
open class ModalAlertUtilities {
    /**
     General error alert message
     - parameter controller: Must be UIViewController. Where to present to alert.
     */
    class func postGenericErrorModal(fromController controller: UIViewController) {
        let alert = UIAlertController(title: "Error", message: "An error occurred. Please try again later", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Okay", style: .cancel) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(cancelAction)
        DispatchQueue.main.async(execute: { () -> Void in
            controller.present(alert, animated: true, completion: nil)
        })
    }
    /**
     Camera permission alert message
     - parameter controller: Must be UIViewController. Where to present to alert.
     Alert tells user to go into setting to enable permission for both camera and photo library
     */
    class func postGoToSettingToEnableCameraAndLibraryModal(fromController controller: UIViewController)
    {
        let alert = UIAlertController(title: "", message: "Allow access to your camera & photo library to start uploading photos with N1", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        let settingsAction = UIAlertAction(title: "Go to Settings", style: .default) { (alertAction) in
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(appSettings)
            }
        }
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        DispatchQueue.main.async(execute: { () -> Void in
            controller.present(alert, animated: true, completion: nil)
        })
    }
    /**
     Camera permission alert message
     - parameter controller: Must be UIViewController. Where to present to alert.
     Alert tells user to go into setting to enable permission for camera
     */
    class func postGoToSettingToEnableCameraModal(fromController controller: UIViewController)
    {
        let alert = UIAlertController(title: "", message: "Allow access to your camera to start taking photos and uploading photos from your library with N1", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        let settingsAction = UIAlertAction(title: "Go to Settings", style: .default) { (alertAction) in
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(appSettings)
            }
        }
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        DispatchQueue.main.async(execute: { () -> Void in
            controller.present(alert, animated: true, completion: nil)
        })
    }
    /**
     Camera permission alert message
     - parameter controller: Must be UIViewController. Where to present to alert.
     Alert tells user to go into setting to enable permission for photo library
     */
    class func postGoToSettingToEnableLibraryModal(fromController controller: UIViewController)
    {
        let alert = UIAlertController(title: "", message: "Allow access to your photo library to start uploading photos from you library with N1", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        let settingsAction = UIAlertAction(title: "Go to Settings", style: .default) { (alertAction) in
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(appSettings)
            }
        }
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        DispatchQueue.main.async(execute: { () -> Void in
            controller.present(alert, animated: true, completion: nil)
        })
    }
}
