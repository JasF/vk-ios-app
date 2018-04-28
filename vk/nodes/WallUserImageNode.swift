//
//  WallUserImageNode.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import NMessenger

@objcMembers class WallUserImageNode : ASCellNode {
    let imageNode : ASNetworkImageNode = ASNetworkImageNode()
    init(_ user: User?) {
        imageNode.setURL(URL.init(string: user!.avatarURLString()), resetToDefault: false)
        super.init()
        self.addSubnode(imageNode)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
       let imagePlace = ASRatioLayoutSpec.init(ratio: 0.5, child: imageNode)
        //collectionNode.style.preferredSize = CGSize(width: constrainedSize.max.width, height: elementSize.height)
        let spec = ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(0,0,0,0), child:imagePlace)
        return spec
    }
    
    
}
