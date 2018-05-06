//
//  AuthorizationNode.swift
//  vk
//
//  Created by Jasf on 06.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import AsyncDisplayKit


@objcMembers class AuthorizationNode : ASDisplayNode {
    let kAuthorizationButtonsSpacing: CGFloat = 30.0
    let kAuthorizationButtonMargin: CGFloat = 30.0
    let kButtonCornerRadius: CGFloat = 4.0
    let kBottomSpacing: CGFloat = 60
    let kBottomSpacingWithoutApp: CGFloat = 90
    
    public var authorizeByAppHandler : (()->Void)?
    public var authorizeByLoginHandler : (()->Void)?
    let appAuthorizationButton = ASButtonNode()
    let loginAuthorizationButton = ASButtonNode()
    let authorizationOverAppAvailable: Bool
    init(_ authorizationOverAppAvailable: Bool) {
        self.authorizationOverAppAvailable = authorizationOverAppAvailable
        super.init()
        self.addSubnode(appAuthorizationButton)
        self.addSubnode(loginAuthorizationButton)
        self.backgroundColor = UIColor(red: 41.0/255.0, green: 171.0/255.0, blue: 226.0/255.0, alpha: 1.0)
        appAuthorizationButton.backgroundColor = UIColor(red: 169.0/255.0, green: 221.0/255.0, blue: 243.0/255.0, alpha: 1.0)
        loginAuthorizationButton.backgroundColor = UIColor(red: 169.0/255.0, green: 221.0/255.0, blue: 243.0/255.0, alpha: 1.0)
        appAuthorizationButton.setAttributedTitle(NSAttributedString.init(string: "authorize_with_app".localized, attributes: TextStyles.authorizationButtonStyle()), for: .normal)
        loginAuthorizationButton.setAttributedTitle(NSAttributedString.init(string: "authorize_with_login".localized, attributes: TextStyles.authorizationButtonStyle()), for: .normal)
        appAuthorizationButton.addTarget(self, action: #selector(authorizeByApp), forControlEvents: .touchUpInside)
        loginAuthorizationButton.addTarget(self, action: #selector(authorizeByLogin), forControlEvents: .touchUpInside)
        for button in [appAuthorizationButton, loginAuthorizationButton] {
            button.style.height = ASDimensionMake(kAuthorizationButtonMargin)
            button.cornerRadius = kButtonCornerRadius
            button.style.flexGrow = 1
            button.style.flexShrink = 1
        }
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var buttons = [ASLayoutElement]()
        if authorizationOverAppAvailable {
            buttons.append(appAuthorizationButton)
        }
        buttons.append(loginAuthorizationButton)
        let spacing = ASLayoutSpec()
        spacing.style.height = ASDimensionMake(authorizationOverAppAvailable ? kBottomSpacing : kBottomSpacingWithoutApp)
        buttons.append(spacing)
        
        var specs = [ASStackLayoutSpec]()
        for button in buttons {
            let spec = ASStackLayoutSpec.init(direction: .horizontal, spacing: 0, justifyContent: .start, alignItems: .start, children: [button])
            specs.append(spec)
        }
        
        let spec = ASStackLayoutSpec.init(direction: .vertical, spacing: kAuthorizationButtonsSpacing, justifyContent: .end, alignItems: .stretch, children: specs)
        spec.style.flexGrow = 1
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(0, -30, 0, -30), child: spec)
    }
    
    func authorizeByApp() {
        if authorizeByAppHandler != nil {
            authorizeByAppHandler?()
        }
    }
    
    func authorizeByLogin() {
        if authorizeByLoginHandler != nil {
            authorizeByLoginHandler?()
        }
    }
}
