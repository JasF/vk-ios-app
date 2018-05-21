//
//  AvatarNameDateNode.swift
//  vk
//
//  Created by Jasf on 30.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

let kMargin : CGFloat = 6.0


@objc protocol AvatarNameDateDelegate {
    func optionsTappedOnAvatarNameDateNode(_ node: AvatarNameDateNode)
}

@objcMembers class AvatarNameDateNode : ASCellNode {
    private weak var _delegate:AvatarNameDateDelegate?;
    open var delegate: AvatarNameDateDelegate? {
        get {
            return _delegate
        }
        set {
            _delegate = newValue
        }
    }
    let textNode : ASTextNode = ASTextNode()
    let timeNode : ASTextNode = ASTextNode()
    let avatarNode : ASNetworkImageNode = ASNetworkImageNode()
    let optionsNode : ASImageNode = ASImageNode()
    var user: User?
    var date: Int = 0
    
    init(_ user: User?, date: Int) {
        self.user = user
        self.date = date
        super.init()
        textNode.attributedText = NSAttributedString.init(string: (user?.nameString())!, attributes: TextStyles.titleStyle())
        
        let dateObject = NSDate.init(timeIntervalSince1970: TimeInterval(date))
        timeNode.attributedText = NSAttributedString.init(string: dateObject.utils_longDayDifferenceFromNow(), attributes: TextStyles.timeStyle())
        self.addSubnode(avatarNode)
        self.addSubnode(textNode)
        self.addSubnode(timeNode)
        self.addSubnode(optionsNode)
        
        optionsNode.image = UIImage(named: "icon_more")
        optionsNode.contentMode = .center
        optionsNode.addTarget(self, action: #selector(AvatarNameDateNode.optionsTapped), forControlEvents: .touchUpInside)
        
        avatarNode.style.width = ASDimensionMake(44)
        avatarNode.style.height = ASDimensionMake(44)
        avatarNode.cornerRadius = avatarNode.style.width.value/2
        avatarNode.url = URL.init(string: (user?.avatarURLString())!)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let spec = ASStackLayoutSpec.init(direction: .vertical, spacing: 6, justifyContent: .start, alignItems: .start, children: [textNode, timeNode])
        spec.style.flexShrink = 1
        spec.style.flexGrow = 1
        let spacer = ASLayoutSpec()
        spacer.style.flexShrink = 1
        spacer.style.flexGrow = 1
        let imageTextSpec = ASStackLayoutSpec.init(direction: .horizontal, spacing: 6, justifyContent: .start, alignItems: .center, children: [avatarNode, spec, spacer, optionsNode] )
        imageTextSpec.style.flexShrink = 1
        imageTextSpec.style.flexGrow = 1
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(kMargin, kMargin, kMargin, kMargin*2), child: imageTextSpec)
    }
    
    func optionsTapped() {
        delegate?.optionsTappedOnAvatarNameDateNode(self)
    }
}
