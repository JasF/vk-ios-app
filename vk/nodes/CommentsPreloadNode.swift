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
    }
    
    public func set(_ preload: Int, remaining: Int) {
        textNode.attributedText = NSAttributedString.init(string: "preload_\(preload)_from_\(remaining)_comments".localized, attributes: TextStyles.titleStyle())
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let spec = ASStackLayoutSpec.init(direction: .vertical, spacing: 0, justifyContent: .start, alignItems: .center, children: [textNode])
        return spec
    }
}
