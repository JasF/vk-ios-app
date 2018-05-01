//
//  CreatePostNode.swift
//  vk
//
//  Created by Jasf on 01.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import NMessenger

@objcMembers class CreatePostNode : ASDisplayNode {
    let textNode = ASEditableTextNode()
    let spacingNode = ASDisplayNode()
    let bottomNode = ASDisplayNode()
    override init() {
        super.init()
        textNode.attributedPlaceholderText = NSAttributedString.init(string: "create_post_what_is_new".localized, attributes: TextStyles.createPostPlaceholderStyle())
        //textNode. //attributedText = NSAttributedString.init(string: "", attributes: TextStyles.createPostStyle())
        textNode.scrollEnabled = false
        textNode.delegate = self
        self.addSubnode(textNode)
        self.addSubnode(spacingNode)
        self.addSubnode(bottomNode)
        bottomNode.backgroundColor = UIColor.green
        bottomNode.style.preferredSize = CGSize(width:50, height:64)
        spacingNode.style.preferredSize = CGSize(width:1, height:64)
    }
    
    override func didLoad() {
        textNode.textView.font = TextStyles.createPostFont()
        textNode.textView.textColor = TextStyles.createPostTextColor();
    }
    
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        //textNode.style.flexGrow = 1
        let spec = ASStackLayoutSpec.init(direction: .vertical, spacing: 0, justifyContent: .start, alignItems: .stretch, children: [spacingNode, textNode, bottomNode])
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(kMargin,kMargin,kMargin,kMargin), child: spec)
    }
}

extension CreatePostNode : ASEditableTextNodeDelegate {
    
}
