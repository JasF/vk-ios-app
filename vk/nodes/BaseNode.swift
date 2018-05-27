//
//  BaseNode.swift
//  Oxy Feed
//
//  Created by Jasf on 27.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objcMembers class BaseNode : ASDisplayNode {
    let node: ASDisplayNode
    private var overlayingNode: ASDisplayNode?
    init(_ node: ASDisplayNode) {
        self.node = node
        super.init()
        addSubnode(node)
    }
    
    override open func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let spec = ASInsetLayoutSpec(insets: UIEdgeInsetsMake(0, 0, 0, 0), child: node)
        if let node = overlayingNode {
            return ASOverlayLayoutSpec(child: spec, overlay: node)
        }
        return spec
    }
    
    public func setOverlayNode(_ node: ASDisplayNode?) {
        self.overlayingNode?.removeFromSupernode()
        self.overlayingNode = node
        if let node = node {
            self.addSubnode(node)
        }
        self.setNeedsLayout()
    }
}
