//
//  WallUserMessageNode.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import NMessenger

@objcMembers class WallUserMessageNode : ASCellNode {
    var user: User? = nil
    let leftButton: ASButtonNode! = ASButtonNode()
    let rightButton: ASButtonNode! = ASButtonNode()
    init(_ user: User?) {
        super.init()
        self.user = user
        self.addSubnode(leftButton)
        self.addSubnode(rightButton)
        leftButton.style.height = ASDimensionMake(40)
        leftButton.cornerRadius = 20
        leftButton.backgroundColor = UIColor.green
        leftButton.setAttributedTitle(NSAttributedString.init(string: "send message", attributes: TextStyles.titleStyle()), for: .normal)
        leftButton.addTarget(self, action: #selector(leftButtonTapped), forControlEvents: .touchUpInside)
        rightButton.style.height = ASDimensionMake(40)
        rightButton.cornerRadius = 20
        rightButton.backgroundColor = UIColor.white
        rightButton.setAttributedTitle(NSAttributedString.init(string: "maybe friend", attributes: TextStyles.titleStyle()), for: .normal)
        rightButton.addTarget(self, action: #selector(rightButtonTapped), forControlEvents: .touchUpInside)
        self.backgroundColor = UIColor.orange
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        leftButton.style.flexGrow = 1
        rightButton.style.flexGrow = 1
        let spec = ASStackLayoutSpec.init(direction: .horizontal, spacing: 20, justifyContent: .start, alignItems: .center, children: [leftButton, rightButton])
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(10,0,10,0), child:spec)
    }
    
    func leftButtonTapped() {
        NSLog("observer left")
    }
    
    func rightButtonTapped() {
        NSLog("observer right")
    }
}
