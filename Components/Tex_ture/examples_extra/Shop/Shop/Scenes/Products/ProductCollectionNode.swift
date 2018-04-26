//
//  ProductCollectionNode.swift
//  Shop
//
//  Created by Dimitri on 15/11/2016.
//  Copyright © 2016 Dimitri. All rights reserved.
//

import UIKit

class ProductCollectionNode: A_SCellNode {

    // MARK: - Variables
    
    private let containerNode: ContainerNode
    
    // MARK: - Object life cycle
    
    init(product: Product) {
        self.containerNode = ContainerNode(node: ProductContentNode(product: product))
        super.init()
        self.selectionStyle = .none
        self.addSubnode(self.containerNode)
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
        let insets = UIEdgeInsetsMake(2, 2, 2, 2)
        return A_SInsetLayoutSpec(insets: insets, child: self.containerNode)
    }
    
}

class ProductContentNode: A_SDisplayNode {
    
    // MARK: - Variables
    
    private let imageNode: A_SNetworkImageNode
    private let titleNode: A_STextNode
    private let subtitleNode: A_STextNode
    
    // MARK: - Object life cycle
    
    init(product: Product) {
        imageNode = A_SNetworkImageNode()
        imageNode.url = URL(string: product.imageURL)
        
        titleNode = A_STextNode()
        let title = NSAttributedString(string: product.title, attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17)])
        titleNode.attributedText = title
        
        subtitleNode = A_STextNode()
        let subtitle = NSAttributedString(string: product.currency + " \(product.price)", attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15)])
        subtitleNode.attributedText = subtitle
        
        super.init()
        
        self.imageNode.addSubnode(self.titleNode)
        self.imageNode.addSubnode(self.subtitleNode)
        self.addSubnode(self.imageNode)
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
        let textNodesStack = A_SStackLayoutSpec(direction: .vertical, spacing: 5, justifyContent: .end, alignItems: .stretch, children: [self.titleNode, self.subtitleNode])
        let insetStack = A_SInsetLayoutSpec(insets: UIEdgeInsetsMake(CGFloat.infinity, 10, 10, 10), child: textNodesStack)
        return A_SOverlayLayoutSpec(child: self.imageNode, overlay: insetStack)
    }
    
}
