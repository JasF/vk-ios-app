//
//  WallUserActionNode.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import NMessenger

@objcMembers class WallUserActionNode : ASCellNode {
    let textNode : ASTextNode! = ASTextNode()
    let numberNode : ASTextNode! = ASTextNode()
    
    init(_ title: String, number: Int) {
        super.init()
        textNode.style.height = ASDimensionMake(40)
        textNode.cornerRadius = 20
        textNode.backgroundColor = UIColor.green
        textNode.attributedText = NSAttributedString.init(string: title, attributes: TextStyles.titleStyle())
        numberNode.attributedText = NSAttributedString.init(string: "\(number)", attributes: TextStyles.nameStyle())
        self.addSubnode(textNode)
        self.addSubnode(numberNode)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        textNode.style.flexGrow = 1
        numberNode.style.flexGrow = 1
        let spec = ASStackLayoutSpec.init(direction: .vertical, spacing: 5, justifyContent: .start, alignItems: .center, children: [textNode, numberNode])
        return spec
    }
}

