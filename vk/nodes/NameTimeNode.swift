//
//  NameTimeNode.swift
//  vk
//
//  Created by Jasf on 29.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import NMessenger

@objcMembers class NameTimeNode : ASControlNode {
    let textNode : ASTextNode! = ASTextNode()
    let timeNode : ASTextNode! = ASTextNode()
    
    init(_ text: String, time: String) {
        super.init()
        textNode.attributedText = NSAttributedString.init(string: text, attributes: TextStyles.titleStyle())
        timeNode.attributedText = NSAttributedString.init(string: time, attributes: TextStyles.timeStyle())
        self.addSubnode(textNode)
        self.addSubnode(timeNode)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let spec = ASStackLayoutSpec.init(direction: .vertical, spacing: 5, justifyContent: .start, alignItems: .start, children: [textNode, timeNode])
        return spec
    }
}
