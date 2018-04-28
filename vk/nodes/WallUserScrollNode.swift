//
//  WallUserScrollNode.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import NMessenger

/*
class WallUserScrollNodeImpl : ASScrollNode {
    override init() {
        super.init()
        for (_, node) in actions.enumerated() {
            self.addSubnode(node)
        }
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let spec = ASStackLayoutSpec.init(direction: .horizontal, spacing: 10, justifyContent: .start, alignItems: .center, children: actions)
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(10,0,10,0), child:spec)
    }
}
*/

class ActionModel : NSObject {
    var text: String
    var number: Int
    init(_ text: String, number: Int) {
        self.text = text
        self.number = number
    }
}
@objcMembers class WallUserScrollNode : ASCellNode {
    var actions: [ActionModel] = [ActionModel]()
    var collectionNode: ASCollectionNode
    var elementSize: CGSize = CGSize(width: 80, height: 100)
    init(_ user: User?) {
        
        actions.append(ActionModel.init("friends", number:119))
        actions.append(ActionModel.init("common", number:10))
        actions.append(ActionModel.init("subscribers", number:98))
        actions.append(ActionModel.init("photos", number:630))
        actions.append(ActionModel.init("videos", number:46))
        
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        layout.itemSize = elementSize
        layout.minimumInteritemSpacing = 20;
        collectionNode = ASCollectionNode.init(collectionViewLayout: layout)
        super.init()
        collectionNode.delegate = self
        collectionNode.dataSource = self
        self .addSubnode(collectionNode)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        collectionNode.style.preferredSize = CGSize(width: constrainedSize.max.width, height: elementSize.height)
        let spec = ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(0,0,0,0), child:collectionNode)
        return spec
    }
    
    override func layout() {
        super.layout()
        collectionNode.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
}

extension WallUserScrollNode : ASCollectionDelegate, ASCollectionDataSource {
    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        return self.actions.count
    }
    
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            let data = self.actions[indexPath.row]
            let node = WallUserActionNode.init(data.text, number:data.number)
            return node
        }
    }
}
