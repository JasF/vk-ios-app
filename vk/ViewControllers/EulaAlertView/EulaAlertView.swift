//
//  EulaAlertView.swift
//  Oxy Feed
//
//  Created by Jasf on 23.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import UIKit

import DOCheckboxControl

class EulaAlertView : UIView {
    @IBOutlet var textLabel : UILabel?
    @IBOutlet var checkbox: CheckboxControl?
    @IBOutlet var checkboxLabel: UILabel?
    class func instanceFromNib() -> UIView {
        return UINib(nibName: "EulaAlertView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UIView
    }
    @objc func tapped() {
        checkbox?.isSelected = !(checkbox?.isSelected)!
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //let tgr = UITapGestureRecognizer(target: self, action: #selector(self.tapped))
        //checkbox?.addGestureRecognizer(tgr)
        self.backgroundColor = UIColor.clear
        let paragraphStyle = NSMutableParagraphStyle()
        let attstr = NSMutableAttributedString(string: "eula_alert_message".localized)
        paragraphStyle.hyphenationFactor = 1.0
        attstr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(0..<attstr.length))
        textLabel?.attributedText = attstr
        
        textLabel?.attributedText = attstr
        checkboxLabel?.text = "eula_accept".localized
        checkbox?.layer.borderColor = UIColor.black.cgColor
        checkbox?.layer.borderWidth = 1.0
    }
}
