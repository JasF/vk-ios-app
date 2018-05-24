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
    let alert:AlertController!
    override init() {
        let style = AlertControllerStyle(rawValue:1)!
        alert = AlertController(title: nil, message: nil, preferredStyle: style)
        super.init()
    }
    var parentViewController: UIViewController?
    var needsShowEulaViewControllerBlock: (()->Void)?
    var finishedBlock: ((Bool)->Void)?
    public func present(_ viewController: UIViewController) {
        parentViewController = viewController
        let alertView = EulaAlertView.instanceFromNib()
        alertView.eulaTappedBlock = { [weak self] in
            if self?.needsShowEulaViewControllerBlock != nil {
                self?.needsShowEulaViewControllerBlock!()
            }
        }
        let contentView = alert.contentView
        alertView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(alertView)
        alertView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        alertView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        alertView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        let continueAction = AlertAction(title: "eula_continue".localized, style: .preferred, handler: { [weak self] (action) in
            if self?.finishedBlock != nil {
                self?.finishedBlock!(alertView.checkbox!.isSelected)
            }
        })
        continueAction.isEnabled = false
        alertView.checkboxValueChangedBlock = { (selected) in
            continueAction.isEnabled = selected
        }
        alert.addAction(continueAction)
        alert.addAction(AlertAction(title: "cancel".localized, style: .normal, handler: { [weak self] (action) in
            if self?.finishedBlock != nil {
                self?.finishedBlock!(false)
            }
        }))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[alertView]-|", options: [], metrics: nil, views: ["alertView": alertView]))
        contentView.isUserInteractionEnabled = true
        alert.present()
    }
    
    public func dismiss(_ animated:Bool, completion: @escaping (()->Void)) {
        alert.dismiss(animated: animated, completion: completion)
    }
}
