//
//  OfflineNode.swift
//  Oxy Feed
//
//  Created by Jasf on 27.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objcMembers class OfflineNode : ASDisplayNode {
    let button = ASButtonNode()
    let text = ASTextNode()
    var repeatBlock: (()->Void)? = nil
    override init() {
        super.init()
        self.addSubnode(button)
        self.addSubnode(text)
        button.style.height = ASDimensionMake(30)
        button.cornerRadius = button.style.height.value/2
        button.backgroundColor = TextStyles.buttonColor()
        button.setAttributedTitle(NSAttributedString.init(string: "offline_button_text".localized, attributes: TextStyles.buttonTextStyle()), for: .normal)
        button.contentEdgeInsets = UIEdgeInsetsMake(0, 12, 0, 12)
        button.addTarget(self, action: #selector(buttonTapped), forControlEvents: .touchUpInside)
        text.attributedText = NSAttributedString.init(string: "offline_text".localized, attributes: TextStyles.offlineTextStyle())
    }
    
    @objc private func buttonTapped() {
        repeatBlock?()
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let topSpacing = ASLayoutSpec()
        let bottomSpacing = ASLayoutSpec()
        for spacing in [topSpacing, bottomSpacing] {
            spacing.style.flexGrow = 1
        }
        let spec = ASStackLayoutSpec.init(direction: .vertical, spacing: 8, justifyContent: .start, alignItems: .center, children: [topSpacing, text, button, bottomSpacing])
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(8,8,8,8), child:spec)
    }
}
