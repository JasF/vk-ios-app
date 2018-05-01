//
//  CommentsPreloadNode.swift
//  vk
//
//  Created by Jasf on 30.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import NMessenger

@objcMembers class CommentsPreloadNode : ASCellNode {
    let textNode : ASTextNode! = ASTextNode()
    var model: CommentsPreloadModel!
    init(_ model: CommentsPreloadModel?) {
        self.model = model
        super.init()
        set((model?.preload)!, remaining: (model?.remaining)!)
        self.addSubnode(textNode)
        model?.cellNode = self
    }
    
    public func set(_ preload: Int, remaining: Int) {
        textNode.attributedText = NSAttributedString.init(string: "\("preload_comments_first".localized)\(preload)\("preload_comments_second".localized)\(remaining)\("preload_comments_third".localized)".localized, attributes: TextStyles.buttonStyle())
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let spec = ASStackLayoutSpec.init(direction: .vertical, spacing: 0, justifyContent: .start, alignItems: .center, children: [textNode])
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(kMargin*2, kMargin, kMargin*2, kMargin), child: spec)
    }
}
