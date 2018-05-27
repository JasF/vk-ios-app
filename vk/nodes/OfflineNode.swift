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
    override init() {
        super.init()
        self.addSubnode(button)
        self.addSubnode(text)
        button.style.height = ASDimensionMake(30)
        button.cornerRadius = button.style.height.value/2
        button.backgroundColor = TextStyles.buttonColor()
        button.setAttributedTitle(NSAttributedString.init(string: "send_message".localized, attributes: TextStyles.buttonTextStyle()), for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), forControlEvents: .touchUpInside)
        text.attributedText = NSAttributedString.init(string: "offline_text".localized, attributes: TextStyles.offlineTextStyle())
    }
    
    @objc private func buttonTapped() {
        
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let spec = ASStackLayoutSpec.init(direction: .vertical, spacing: 8, justifyContent: .start, alignItems: .center, children: [text, button])
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(8,8,8,8), child:spec)
    }
}
