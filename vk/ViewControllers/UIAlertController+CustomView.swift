//
//  UIAlertController+CustomView.swift
//  Oxy Feed
//
//  Created by Jasf on 23.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

extension UIAlertController {
    
    /// Creates a `UIAlertController` with a custom `UIView` instead the message text.
    /// - Note: In case anything goes wrong during replacing the message string with the custom view, a fallback message will
    /// be used as normal message string.
    ///
    /// - Parameters:
    ///   - title: The title text of the alert controller
    ///   - customView: A `UIView` which will be displayed in place of the message string.
    ///   - fallbackMessage: An optional fallback message string, which will be displayed in case something went wrong with inserting the custom view.
    ///   - preferredStyle: The preferred style of the `UIAlertController`.
    convenience init(title: String?, customView: UIView, fallbackMessage: String?, preferredStyle: UIAlertControllerStyle) {
        
        let marker = "__CUSTOM_CONTENT_MARKER__"
        self.init(title: title, message: marker, preferredStyle: preferredStyle)
        
        // Try to find the message label in the alert controller's view hierarchie
        if let customContentPlaceholder = self.view.findLabel(withText: marker),
            let customContainer =  customContentPlaceholder.superview {
            
            // The message label was found. Add the custom view over it and fix the autolayout...
            customContainer.addSubview(customView)
            
            customView.translatesAutoresizingMaskIntoConstraints = false
            customContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[customView]-|", options: [], metrics: nil, views: ["customView": customView]))
            
            customContainer.centerXAnchor.constraint(equalTo: customView.centerXAnchor).isActive = true
            customContainer.topAnchor.constraint(equalTo: customView.topAnchor).isActive = true
            customContainer.bottomAnchor.constraint(equalTo: customView.bottomAnchor).isActive = true

            /*
            customContainer.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[customView]-|", options: [], metrics: nil, views: ["customView": customView]))
 */
            /*
            customContainer.addConstraint(NSLayoutConstraint(item: customContentPlaceholder,
                                                             attribute: .top,
                                                             relatedBy: .equal,
                                                             toItem: customView,
                                                             attribute: .top,
                                                             multiplier: 1,
                                                             constant: 0))
            
 
            customContainer.addConstraint(NSLayoutConstraint(item: customContentPlaceholder,
                                                             attribute: .height,
                                                             relatedBy: .equal,
                                                             toItem: customView,
                                                             attribute: .height,
                                                             multiplier: 1,
                                                             constant: 0))

            customContainer.addConstraint(NSLayoutConstraint(item: customContainer,
                                                             attribute: .bottom,
                                                             relatedBy: .equal,
                                                             toItem: customView,
                                                             attribute: .bottom,
                                                             multiplier: 1,
                                                             constant: 0))
 */
            customContentPlaceholder.text = ""
        } else { // In case something fishy is going on, fall back to the standard behaviour and display a fallback message string
            self.message = fallbackMessage
        }
    }
}

private extension UIView {
    
    /// Searches a `UILabel` with the given text in the view's subviews hierarchy.
    ///
    /// - Parameter text: The label text to search
    /// - Returns: A `UILabel` in the view's subview hierarchy, containing the searched text or `nil` if no `UILabel` was found.
    func findLabel(withText text: String) -> UILabel? {
        if let label = self as? UILabel, label.text == text {
            return label
        }
        
        for subview in self.subviews {
            if let found = subview.findLabel(withText: text) {
                return found
            }
        }
        
        return nil
    }
}
