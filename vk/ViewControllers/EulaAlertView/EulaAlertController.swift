//
//  EulaAlertController.swift
//  Oxy Feed
//
//  Created by Jasf on 23.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

import SDCAlertView

@objcMembers class EulaAlertController : NSObject {
    override init() {
        super.init()
    }
    
    public func present(_ viewController: UIViewController) {
        let customView = EulaAlertView.instanceFromNib()
        customView.clipsToBounds = true
        customView.translatesAutoresizingMaskIntoConstraints = false
        
        let style = AlertControllerStyle(rawValue:1)!
        let alert = AlertController(title: nil, message: "eula_alert_message".localized, preferredStyle: style)

        
        let alertView = EulaAlertView.instanceFromNib()
        let contentView = alert.contentView
        alertView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(alertView)
        alertView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        alertView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        alertView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        alert.addAction(AlertAction(title: "OK", style: .normal))
        alert.addAction(AlertAction(title: "Delete", style: .destructive))
    
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[alertView]-|", options: [], metrics: nil, views: ["alertView": alertView]))
        contentView.isUserInteractionEnabled = true
        
        alert.present()
        /*
        // Create the alert and show it
        let alert = UIAlertController(title: nil,
                                      customView: customView,
                                      fallbackMessage: nil,
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "eula_button_accept".localized, style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "eula_cancel".localized, style: .destructive, handler: nil))
 */
        
        //viewController.present(alert, animated: true, completion: nil)
    }
    
    
}
