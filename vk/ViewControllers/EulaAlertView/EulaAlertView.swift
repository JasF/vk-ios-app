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
import TTTAttributedLabel

class EulaAlertView : UIView {
    @IBOutlet var textLabel : TTTAttributedLabel?
    @IBOutlet var checkbox: CheckboxControl?
    @IBOutlet var checkboxLabel: UILabel?
    public var eulaTappedBlock: (() -> Void)?
    public var checkboxValueChangedBlock: ((Bool) -> Void)?
    class func instanceFromNib() -> EulaAlertView {
        return UINib(nibName: "EulaAlertView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! EulaAlertView
    }
    @objc func tapped() {
        checkbox?.isSelected = !(checkbox?.isSelected)!
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        checkbox?.addTarget(self, action: #selector(checkboxValueChanged), for: .valueChanged)
        self.backgroundColor = UIColor.clear
        let paragraphStyle = NSMutableParagraphStyle()
        let string = "eula_alert_message_begin".localized + "eula_alert_message_link".localized
        let attstr = NSMutableAttributedString(string: string)
        attstr.setAttributes(TextStyles.eulaTextStyle(), range: NSMakeRange(0, string.count))
        paragraphStyle.hyphenationFactor = 1.0
        attstr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(0..<attstr.length))
        textLabel?.attributedText = attstr
        checkboxLabel?.text = "eula_accept".localized
        checkbox?.layer.borderColor = UIColor.black.cgColor
        checkbox?.layer.borderWidth = 1.0
        
        let linkAttributes = [ NSAttributedStringKey.foregroundColor: UIColor.blue,
                               .underlineStyle: NSUnderlineStyle.styleSingle.rawValue ] as [NSAttributedStringKey : Any]
        let activeLinkAttributes = [ NSAttributedStringKey.foregroundColor: UIColor.blue.withAlphaComponent(0.5),
                                     .underlineStyle: NSUnderlineStyle.styleSingle.rawValue ] as [NSAttributedStringKey : Any]
        textLabel?.linkAttributes = linkAttributes
        textLabel?.activeLinkAttributes = activeLinkAttributes
        
        let linkRange = (string as NSString).range(of: "eula_alert_message_link".localized)
        let url = NSURL(string:"http://link")!
        textLabel?.addLink(to: url as URL?, with:linkRange).linkTapBlock = { [weak self] (label, link) in
            if self?.eulaTappedBlock != nil {
                self?.eulaTappedBlock!()
            }
        }
    }
    @objc private func checkboxValueChanged() {
        if checkboxValueChangedBlock != nil {
            checkboxValueChangedBlock!((checkbox?.isSelected)!)
        }
    }
}
