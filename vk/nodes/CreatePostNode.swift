//
//  CreatePostNode.swift
//  vk
//
//  Created by Jasf on 01.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import NMessenger

@objc protocol CreatePostNodeDelegate {
    func textChanged(_ text: NSString?)
}

@objcMembers class CreatePostNode : ASDisplayNode {
    let textNode = ASEditableTextNode()
    let spacingNode = ASDisplayNode()
    weak var delegate : CreatePostNodeDelegate?
    var oldContentSize: CGSize
    override init() {
        oldContentSize = CGSize(width: 0, height: 0)
        super.init()
        textNode.attributedPlaceholderText = NSAttributedString.init(string: "create_post_what_is_new".localized, attributes: TextStyles.createPostPlaceholderStyle())
        textNode.delegate = self
        self.addSubnode(textNode)
        self.addSubnode(spacingNode)
        spacingNode.style.preferredSize = CGSize(width:1, height:64)
    }
    
    override func didLoad() {
        textNode.textView.font = TextStyles.createPostFont()
        textNode.textView.textColor = TextStyles.createPostTextColor();
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let spec = ASStackLayoutSpec.init(direction: .vertical, spacing: 0, justifyContent: .start, alignItems: .stretch, children: [spacingNode, textNode])
        textNode.style.flexGrow = 1
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(kMargin,kMargin,kMargin,kMargin), child: spec)
    }
    
    public func text() -> NSString? {
        return textNode.textView.text as NSString?
    }
}

extension CreatePostNode : ASEditableTextNodeDelegate {
    func editableTextNode(_ editableTextNode: ASEditableTextNode, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let string = textNode.textView.text as NSString?
        let newText = string?.replacingCharacters(in: range, with: text) as NSString?
        delegate?.textChanged(newText)
        return true;
    }
}

