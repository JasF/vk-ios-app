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


@objc enum WallUserScrollActions : Int {
    case friends
    case common
    case subscribers
    case photos
    case videos
}

class ActionModel : NSObject {
    var text: String
    var number: Int
    var action: WallUserScrollActions
    init(_ text: String, number: Int, action: WallUserScrollActions) {
        self.text = text
        self.number = number
        self.action = action
    }
}

@objc protocol WallUserScrollNodeDelegate {
    func friendsTapped()
    func commonTapped()
    func subscribersTapped()
    func photosTapped()
    func videosTapped()
}

@objcMembers class WallUserScrollNode : ASCellNode {
    var actions: [ActionModel] = [ActionModel]()
    var collectionNode: ASCollectionNode
    var elementSize: CGSize = CGSize(width: 80, height: 100)
    weak var delegate: WallUserScrollNodeDelegate?
    init(_ user: User?) {
        actions.append(ActionModel.init("friends", number:(user?.friends_count)!, action:.friends))
        if (user?.currentUser)! == false {
            //actions.append(ActionModel.init("common", number:(user?.common_count)!, action:.common))
        }
        actions.append(ActionModel.init("photos", number:(user?.photos_count)!, action:.photos))
        actions.append(ActionModel.init("videos", number:(user?.videos_count)!, action:.videos))
        actions.append(ActionModel.init("interest_pages", number:(user?.subscriptions_count)!, action:.subscribers))
        
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
    
    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        let data = actions[indexPath.row]
        switch (data.action) {
        case .friends: self.delegate?.friendsTapped(); break
        case .common: self.delegate?.commonTapped(); break
        case .subscribers: self.delegate?.subscribersTapped(); break
        case .photos: self.delegate?.photosTapped(); break
        case .videos: self.delegate?.videosTapped(); break
        }
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            let data = self.actions[indexPath.row]
            let node = WallUserActionNode.init(data.text, number:data.number)
            return node
        }
    }
}
