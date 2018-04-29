//
//  WallUserScrollNode.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import NMessenger

@objc enum WallUserScrollActions : Int {
    case friends
    case common
    case subscribers
    case photos
    case videos
    case followers
    case groups
}

class ActionModel : NSObject {
    var text: String
    var action: WallUserScrollActions
    var _number: Int = 0
    var number: Int {
        get {
            return _number
        }
        set {
            _number = newValue
            guard let node = self.actionNode else { return }
            node.setNumber(_number)
        }
    }
    weak var actionNode: WallUserActionNode?
    init(_ text: String, number: Int, action: WallUserScrollActions) {
        self.text = text
        self.action = action
        super.init()
        self.number = number
    }
}

@objc protocol WallUserScrollNodeDelegate {
    func friendsTapped()
    func commonTapped()
    func subscribtionsTapped()
    func followersTapped()
    func photosTapped()
    func videosTapped()
    func groupsTapped()
}

@objcMembers class WallUserScrollNode : ASCellNode {
    var actions: [ActionModel] = [ActionModel]()
    var collectionNode: ASCollectionNode
    var elementSize: CGSize = CGSize(width: 80, height: 60)
    weak var delegate: WallUserScrollNodeDelegate?
    init(_ user: User?) {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12;
        layout.minimumLineSpacing = 1000;
        collectionNode = ASCollectionNode.init(collectionViewLayout: layout)
        super.init()
        configureActions(user);
        collectionNode.delegate = self
        collectionNode.dataSource = self
        self .addSubnode(collectionNode)
    }
    
    func configureActions(_ user: User?) {
        actions.append(ActionModel.init("friends".localized, number:(user?.friends_count)!, action:.friends))
        actions.append(ActionModel.init("followers".localized, number:(user?.followers_count)!, action:.followers))
        if (user?.currentUser)! == false {
            //actions.append(ActionModel.init("common", number:(user?.common_count)!, action:.common))
        }
        actions.append(ActionModel.init("groups".localized, number:(user?.groups_count)!, action:.groups))
        actions.append(ActionModel.init("photos".localized, number:(user?.photos_count)!, action:.photos))
        actions.append(ActionModel.init("videos".localized, number:(user?.videos_count)!, action:.videos))
        actions.append(ActionModel.init("interest_pages".localized, number:(user?.subscriptions_count)!, action:.subscribers))
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        collectionNode.style.preferredSize = CGSize(width: constrainedSize.max.width, height: elementSize.height)
        let spec = ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(0,0,0,0), child:collectionNode)
        return spec
    }
    
    
    override func layout() {
        super.layout()
        collectionNode.contentInset = UIEdgeInsetsMake(0, 12, 0, 12)
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
        case .subscribers: self.delegate?.subscribtionsTapped(); break
        case .followers: self.delegate?.followersTapped(); break
        case .photos: self.delegate?.photosTapped(); break
        case .videos: self.delegate?.videosTapped(); break
        case .groups: self.delegate?.groupsTapped(); break
        }
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            let data = self.actions[indexPath.row]
            let node = WallUserActionNode.init(data.text, number:data.number)
            data.actionNode = node
            return node
        }
    }
    
    func collectionNode(_ collectionNode: ASCollectionNode, constrainedSizeForItemAt indexPath: IndexPath) -> ASSizeRange {
        var size = ASSizeRangeUnconstrained
        size.min.height = 40
        size.max.height = 40
        return size
    }
}
