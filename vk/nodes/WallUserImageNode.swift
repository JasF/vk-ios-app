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
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: frame.size.width, height: frame.size.height)
        return gradient
    }
}

@objcMembers class WallUserImageNode : ASCellNode {
    let imageNode : ASNetworkImageNode = ASNetworkImageNode()
    let usernameNode: ASTextNode = ASTextNode()
    init(_ user: User?) {
        imageNode.setURL(URL.init(string: user!.avatarURLString()), resetToDefault: false)
        usernameNode.attributedText = NSAttributedString.init(string: user!.nameString(), attributes: TextStyles.usernameGradientStyle())
        usernameNode.style.height = ASDimensionMake(40)
        super.init()
        self.addSubnode(imageNode)
        self.addSubnode(usernameNode)
    }
    
    override func didLoad() {
        self.imageNode.layer.addSublayer(self.view.gradient(color1: UIColor.black.withAlphaComponent(0), color2: UIColor.black.withAlphaComponent(1)))
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let imagePlace = ASRatioLayoutSpec.init(ratio: 0.5, child: imageNode)
        let nameSpec = ASStackLayoutSpec.init(direction: .vertical, spacing: 0, justifyContent: .end, alignItems: .start, children: [usernameNode])
        let spec = ASOverlayLayoutSpec.init(child: imagePlace, overlay: nameSpec)
        return spec
    }
}
