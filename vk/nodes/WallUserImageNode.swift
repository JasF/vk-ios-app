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
    var usernameNode: WallUserImageUsernameNode?
    init(_ user: User?) {
        imageNode.setURL(URL.init(string: user!.bigAvatarURLString()), resetToDefault: false)
        usernameNode = WallUserImageUsernameNode.init(user)
        super.init()
        self.addSubnode(imageNode)
        self.addSubnode(usernameNode!)
    }
    
    override func didLoad() {
        //self.imageNode.layer.addSublayer(self.view.gradient(color1: UIColor.black.withAlphaComponent(0), color2: UIColor.black.withAlphaComponent(1)))
        self.usernameNode?.layer.insertSublayer(self.view.gradient(color1: UIColor.black.withAlphaComponent(0), color2: UIColor.black.withAlphaComponent(1)), at: 0)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let imagePlace = ASRatioLayoutSpec.init(ratio: 0.5, child: imageNode)
        usernameNode?.style.flexGrow = 1.0
        let horSpec = ASStackLayoutSpec.init(direction: .horizontal, spacing: 0, justifyContent: .center, alignItems: .end, children: [usernameNode!])
        let spec = ASOverlayLayoutSpec.init(child: imagePlace, overlay: horSpec)
        return spec
    }
}
