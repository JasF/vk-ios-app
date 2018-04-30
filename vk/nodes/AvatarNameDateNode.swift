//
//  AvatarNameDateNode.swift
//  vk
//
//  Created by Jasf on 30.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objcMembers class AvatarNameDateNode : ASCellNode {
    let textNode : ASTextNode = ASTextNode()
    let timeNode : ASTextNode = ASTextNode()
    let avatarNode : ASNetworkImageNode = ASNetworkImageNode()
    var user: User?
    var date: Int = 0
    
    init(_ user: User?, date: Int) {
        self.user = user
        self.date = date
        super.init()
        textNode.attributedText = NSAttributedString.init(string: (user?.nameString())!, attributes: TextStyles.titleStyle())
        timeNode.attributedText = NSAttributedString.init(string: "\(date)", attributes: TextStyles.timeStyle())
        self.addSubnode(avatarNode)
        self.addSubnode(textNode)
        self.addSubnode(timeNode)
        avatarNode.style.width = ASDimensionMake(44)
        avatarNode.style.height = ASDimensionMake(44)
        avatarNode.cornerRadius = avatarNode.style.width.value/2
        avatarNode.url = URL.init(string: (user?.avatarURLString())!)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let spec = ASStackLayoutSpec.init(direction: .vertical, spacing: 6, justifyContent: .start, alignItems: .start, children: [textNode, timeNode])
        let imageTextSpec = ASStackLayoutSpec.init(direction: .horizontal, spacing: 6, justifyContent: .start, alignItems: .center, children: [avatarNode, spec] )
        return imageTextSpec
    }
}
