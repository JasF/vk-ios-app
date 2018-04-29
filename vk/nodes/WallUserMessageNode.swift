//
//  WallUserMessageNode.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import NMessenger


@objc protocol WallUserMessageNodeDelegate {
    func messageButtonTapped()
    func friendButtonTapped()
}

@objcMembers class WallUserMessageNode : ASCellNode {
    var user: User? = nil
    let leftButton: ASButtonNode! = ASButtonNode()
    let rightButton: ASButtonNode! = ASButtonNode()
    var delegate: WallUserMessageNodeDelegate? = nil
    init(_ user: User?) {
        super.init()
        self.user = user
        self.addSubnode(leftButton)
        self.addSubnode(rightButton)
        leftButton.style.height = ASDimensionMake(30)
        leftButton.cornerRadius = leftButton.style.height.value/2
        leftButton.setAttributedTitle(NSAttributedString.init(string: "send_message".localized, attributes: TextStyles.buttonTextStyle()), for: .normal)
        leftButton.backgroundColor = TextStyles.buttonColor()
        leftButton.addTarget(self, action: #selector(leftButtonTapped), forControlEvents: .touchUpInside)
        rightButton.style.height = leftButton.style.height
        rightButton.cornerRadius = leftButton.style.height.value/2
        var rightAttrString: NSAttributedString!
        if user?.is_friend == 1 {
            rightAttrString = NSAttributedString.init(string: "is_your_friend".localized, attributes: TextStyles.buttonPassiveTextStyle())
        }
        else {
            rightAttrString = NSAttributedString.init(string: "add_to_friends".localized, attributes: TextStyles.buttonTextStyle())
        }
        rightButton.backgroundColor = (user?.is_friend == 1) ? TextStyles.buttonPassiveColor() : TextStyles.buttonColor()
        rightButton.setAttributedTitle(rightAttrString, for: .normal)
        rightButton.addTarget(self, action: #selector(rightButtonTapped), forControlEvents: .touchUpInside)
        
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        leftButton.style.flexGrow = 1
        rightButton.style.flexGrow = 1
        let spec = ASStackLayoutSpec.init(direction: .horizontal, spacing: 8, justifyContent: .start, alignItems: .center, children: [leftButton, rightButton])
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(8,8,8,8), child:spec)
    }
    
    func leftButtonTapped() {
        self.delegate?.messageButtonTapped()
    }
    
    func rightButtonTapped() {
        self.delegate?.friendButtonTapped()
    }
}



