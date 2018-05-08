//
//  WallUserImageNode.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import NMessenger
extension UIView {
    func gradient(color1: UIColor, color2: UIColor) -> CAGradientLayer {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [color1.cgColor, color2.cgColor]
        gradient.locations = [0.0 , 1.0]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.0, y: 1.0)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: frame.size.width, height: 60)
        return gradient
    }
}

class WallUserImageUsernameNode : ASDisplayNode {
    var usernameNode: ASTextNode = ASTextNode()
    init(_ user: User?) {
        usernameNode.attributedText = NSAttributedString.init(string: user!.nameString(), attributes: TextStyles.usernameGradientStyle())
        //usernameNode.backgroundColor = UIColor.green
        super.init()
        self.addSubnode(usernameNode)
    }
    
    override func didLoad() {
        self.usernameNode.layer.addSublayer(self.usernameNode.view.gradient(color1: UIColor.red.withAlphaComponent(0.5), color2: UIColor.black.withAlphaComponent(1)))
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(8,12,8,0), child: usernameNode)
    }
}

@objcMembers class WallUserImageNode : ASCellNode {
    let imageNode : ASNetworkImageNode = ASNetworkImageNode()
    var coverNode : ASNetworkImageNode?
    var pageNode : ImageAndLabelsNode?
    var coverRatio : CGFloat = 1.0
    var usernameNode: WallUserImageUsernameNode?
    var model: WallUserCellModel? = nil
    
    init(_ model: WallUserCellModel?) {
        super.init()
        let user = model?.user
        self.model = model
        self.model?.delegate = self
        if user?.type != nil && (user?.isGroup())! {
            let cover = user?.getCover()
            if let url = cover?.url {
                coverNode = ASNetworkImageNode.init()
                coverRatio = CGFloat((cover?.height)!) / CGFloat((cover?.width)!)
                coverNode?.setURL(URL.init(string: url as String), resetToDefault: false)
                addSubnode(coverNode!)
            }
            pageNode = ImageAndLabelsNode.init(user!.bigAvatarURLString(), topLine: user!.nameString(), bottomLine: user!.status)
            addSubnode(pageNode!)
        }
        else {
            usernameNode = WallUserImageUsernameNode.init(user)
            imageNode.setURL(URL.init(string: user!.bigAvatarURLString()), resetToDefault: false)
            self.addSubnode(imageNode)
            self.addSubnode(usernameNode!)
        }
    }
    
    override func didLoad() {
        self.usernameNode?.layer.insertSublayer(self.view.gradient(color1: UIColor.black.withAlphaComponent(0), color2: UIColor.black.withAlphaComponent(1)), at: 0)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        if let pageNode = self.pageNode {
            var array = [ASLayoutElement]()
            if let node = coverNode {
                let coverPlace = ASRatioLayoutSpec.init(ratio: coverRatio, child: node)
                array.append(coverPlace)
            }
            array.append(pageNode)
            let verSpec = ASStackLayoutSpec.init(direction: .vertical, spacing: 0, justifyContent: .start, alignItems: .start, children: array)
            return verSpec
        }
        let imagePlace = ASRatioLayoutSpec.init(ratio: 0.5, child: imageNode)
        usernameNode?.style.flexGrow = 1.0
        let horSpec = ASStackLayoutSpec.init(direction: .horizontal, spacing: 0, justifyContent: .center, alignItems: .end, children: [usernameNode!])
        let spec = ASOverlayLayoutSpec.init(child: imagePlace, overlay: horSpec)
        return spec
    }
}

extension WallUserImageNode : WallUserCellModelDelegate {
    func modelDidUpdated() {
        if let user = self.model?.user {
            if user.isGroup() {
                if let coverNode = self.coverNode {
                    let cover = user.getCover()
                    if let url = cover?.url {
                        coverNode.setURL(URL.init(string: url as String), resetToDefault: false)
                    }
                }
                if let pageNode = self.pageNode {
                    pageNode.set(user.bigAvatarURLString(), topLine:user.nameString(), bottomLine:user.status)
                }
            }
            else {
                imageNode.setURL(URL.init(string: user.bigAvatarURLString()), resetToDefault: false)
            }
        }
    }
}
