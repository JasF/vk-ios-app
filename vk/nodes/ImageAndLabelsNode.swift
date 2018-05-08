//
//  ImageAndLabelsNode.swift
//  vk
//
//  Created by Jasf on 30.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objcMembers class ImageAndLabelsNode : ASCellNode {
    let topLine : ASTextNode = ASTextNode()
    let bottomLine : ASTextNode = ASTextNode()
    let imageNode : ASNetworkImageNode = ASNetworkImageNode()
    
    init(_ imageURL : String, topLine: String, bottomLine: String) {
        super.init()
        self.topLine.attributedText = NSAttributedString.init(string: topLine, attributes: TextStyles.titleStyle())
        self.bottomLine.attributedText = NSAttributedString.init(string: bottomLine, attributes: TextStyles.titleLightStyle())
        self.addSubnode(imageNode)
        self.addSubnode(self.topLine)
        self.addSubnode(self.bottomLine)
        imageNode.style.width = ASDimensionMake(80)
        imageNode.style.height = ASDimensionMake(80)
        imageNode.url = URL.init(string: imageURL)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let spec = ASStackLayoutSpec.init(direction: .vertical, spacing: 6, justifyContent: .start, alignItems: .start, children: [topLine, bottomLine])
        spec.style.flexShrink = 1
        spec.style.flexGrow = 1
        let imageTextSpec = ASStackLayoutSpec.init(direction: .horizontal, spacing: 16, justifyContent: .start, alignItems: .center, children: [imageNode, spec] )
        imageTextSpec.style.flexShrink = 1
        imageTextSpec.style.flexGrow = 1
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(kMargin, kMargin, kMargin, kMargin), child: imageTextSpec)
    }
}
