//
//  ShopCellNode.swift
//  Shop
//
//  Created by Dimitri on 14/11/2016.
//  Copyright © 2016 Dimitri. All rights reserved.
//

import UIKit

class ShopCellNode: A_SCellNode {
    
    // MARK: - Variables
    
    private let containerNode: ContainerNode
    private let categoryNode: CategoryNode
    
    // MARK: - Object life cycle
    
    init(category: Category) {
        categoryNode = CategoryNode(category: category)
        containerNode = ContainerNode(node: categoryNode)
        super.init()
        self.selectionStyle = .none
        self.addSubnode(self.containerNode)
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
        return A_SInsetLayoutSpec(insets: UIEdgeInsetsMake(5, 10, 5, 10), child: self.containerNode)
    }
    
}

class ContainerNode: A_SDisplayNode {
    
    // MARK: - Variables
    
    private let contentNode: A_SDisplayNode
    
    // MARK: - Object life cycle
    
    init(node: A_SDisplayNode) {
        contentNode = node
        super.init()
        self.backgroundColor = UIColor.containerBackgroundColor()
        self.addSubnode(self.contentNode)
    }
    
    // MARK: - Node life cycle
    
    override func didLoad() {
        super.didLoad()
        self.layer.cornerRadius = 5.0
        self.layer.borderColor = UIColor.containerBorderColor().cgColor
        self.layer.borderWidth = 1.0
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
        return A_SInsetLayoutSpec(insets: UIEdgeInsetsMake(8, 8, 8, 8), child: self.contentNode)
    }
    
}

class CategoryNode: A_SDisplayNode {
    
    // MARK: - Variables
    
    private let imageNode: A_SNetworkImageNode
    private let titleNode: A_STextNode
    private let subtitleNode: A_STextNode
    
    // MARK: - Object life cycle
    
    init(category: Category) {
        imageNode = A_SNetworkImageNode()
        imageNode.url = URL(string: category.imageURL)
        
        titleNode = A_STextNode()
        let title = NSAttributedString(string: category.title, attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17)])
        titleNode.attributedText = title
        
        subtitleNode = A_STextNode()
        let subtitle = NSAttributedString(string: "\(category.numberOfProducts) products", attributes: [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15)])
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
