//
//  WallUserActionNode.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import NMessenger


@objcMembers class WallUserActionNode : ChatBaseNodeCell {
    let aTextNode : ASTextNode! = ASTextNode()
    let numberNode : ASTextNode! = ASTextNode()
    
    init(_ title: String, number: Int) {
        super.init()
        aTextNode.attributedText = NSAttributedString.init(string: title, attributes: TextStyles.titleStyle())
        setNumber(number)
        self.addSubnode(aTextNode)
        self.addSubnode(numberNode)
    }
    
    public func setNumber(_ number: Int) {
        numberNode.attributedText = NSAttributedString.init(string: "\(number)", attributes: TextStyles.nameStyle())
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        aTextNode.style.flexGrow = 1
        numberNode.style.flexGrow = 1
        let spec = ASStackLayoutSpec.init(direction: .vertical, spacing: 5, justifyContent: .start, alignItems: .center, children: [aTextNode, numberNode])
        return spec
    }
}

