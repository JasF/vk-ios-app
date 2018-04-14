//
//  ProductNode.swift
//  Shop
//
//  Created by Dimitri on 15/11/2016.
//  Copyright © 2016 Dimitri. All rights reserved.
//

import UIKit

class ProductNode: A_SDisplayNode {
    
    // MARK: - Variables
    
    private let imageNode: A_SNetworkImageNode
    private let titleNode: A_STextNode
    private let priceNode: A_STextNode
    private let starRatingNode: StarRatingNode
    private let reviewsNode: A_STextNode
    private let descriptionNode: A_STextNode
    
    private let product: Product
    
    // MARK: - Object life cycle
    
    init(product: Product) {
        self.product = product
        
        imageNode = A_SNetworkImageNode()
        titleNode = A_STextNode()
        starRatingNode = StarRatingNode(rating: product.starRating)
        priceNode = A_STextNode()
        reviewsNode = A_STextNode()
        descriptionNode = A_STextNode()
        
        super.init()
        self.setupNodes()
        self.buildNodeHierarchy()
    }
    
    // MARK: - Setup nodes
    
    private func setupNodes() {
        self.setupImageNode()
        self.setupTitleNode()
        self.setupDescriptionNode()
        self.setupPriceNode()
        self.setupReviewsNode()
    }
    
    private func setupImageNode() {
        self.imageNode.url = URL(string: self.product.imageURL)
        self.imageNode.preferredFrameSize = CGSize(width: UIScreen.main.bounds.width, height: 300)
    }
    
    private func setupTitleNode() {
        self.titleNode.attributedText = NSAttributedString(string: self.product.title, attributes: self.titleTextAttributes())
        self.titleNode.maximumNumberOfLines = 1
        self.titleNode.truncationMode = .byTruncatingTail
    }
    
    private var titleTextAttributes = {
        return [NSForegroundColorAttributeName: UIColor.black, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 16)]
    }
    
    private func setupDescriptionNode() {
        self.descriptionNode.attributedText = NSAttributedString(string: self.product.descriptionText, attributes: self.descriptionTextAttributes())
        self.descriptionNode.maximumNumberOfLines = 0
    }
    
    private var descriptionTextAttributes = {
        return [NSForegroundColorAttributeName: UIColor.darkGray, NSFontAttributeName: UIFont.systemFont(ofSize: 14)]
    }
    
    private func setupPriceNode() {
        self.priceNode.attributedText = NSAttributedString(string: self.product.currency + " \(self.product.price)", attributes: self.priceTextAttributes())
    }
    
    private var priceTextAttributes = {
        return [NSForegroundColorAttributeName: UIColor.red, NSFontAttributeName: UIFont.boldSystemFont(ofSize: 15)]
    }
    
    private func setupReviewsNode() {
        self.reviewsNode.attributedText = NSAttributedString(string: "\(self.product.numberOfReviews) reviews", attributes: self.reviewsTextAttributes())
    }
    
    private var reviewsTextAttributes = {
        return [NSForegroundColorAttributeName: UIColor.lightGray, NSFontAttributeName: UIFont.systemFont(ofSize: 14)]
    }
    
    // MARK: - Build node hierarchy
    
    private func buildNodeHierarchy() {
        self.addSubnode(imageNode)
        self.addSubnode(titleNode)
        self.addSubnode(descriptionNode)
        self.addSubnode(starRatingNode)
        self.addSubnode(priceNode)
        self.addSubnode(reviewsNode)
    }
    
    // MARK: - Layout
    
    override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
        let spacer = A_SLayoutSpec()
        spacer.flexGrow = true
        self.titleNode.flexShrink = true
        let titlePriceSpec = A_SStackLayoutSpec(direction: .horizontal, spacing: 2.0, justifyContent: .start, alignItems: .center, children: [self.titleNode, spacer, self.priceNode])
        titlePriceSpec.alignSelf = .stretch
        let starRatingReviewsSpec = A_SStackLayoutSpec(direction: .horizontal, spacing: 25.0, justifyContent: .start, alignItems: .center, children: [self.starRatingNode, self.reviewsNode])
        let contentSpec = A_SStackLayoutSpec(direction: .vertical, spacing: 8.0, justifyContent: .start, alignItems: .stretch, children: [titlePriceSpec, starRatingReviewsSpec, self.descriptionNode])
        contentSpec.flexShrink = true
        let insetSpec = A_SInsetLayoutSpec(insets: UIEdgeInsetsMake(12.0, 12.0, 12.0, 12.0), child: contentSpec)
        let finalSpec = A_SStackLayoutSpec(direction: .vertical, spacing: 5.0, justifyContent: .start, alignItems: .center, children: [self.imageNode, insetSpec])
        return finalSpec
    }
    
}
