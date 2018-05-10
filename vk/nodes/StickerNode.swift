//
//  StickerNode.swift
//  vk
//
//  Created by Jasf on 10.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
@objcMembers class StickerNode : ASCellNode {
    let imageNode : ASNetworkImageNode = ASNetworkImageNode()
    let photo: Photo
    init(_ sticker : Sticker) {
        photo = sticker.photoForChatCell()
        super.init()
        self.addSubnode(imageNode)
        imageNode.style.maxWidth = ASDimensionMake(photo.width);
        imageNode.style.maxHeight = ASDimensionMake(photo.height);
        imageNode.setURL(URL.init(string: self.photo.url!), resetToDefault: false)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let spec = ASRatioLayoutSpec(ratio: photo.height/photo.width, child: imageNode)
        spec.style.flexShrink = 1
        imageNode.style.flexShrink = 1
        let hspec = ASStackLayoutSpec(direction: .horizontal, spacing: 0, justifyContent: .start, alignItems: .start, children: [spec])
        return hspec
    }
}
