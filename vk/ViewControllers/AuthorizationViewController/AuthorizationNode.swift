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
    let kAuthorizationButtonMargin: CGFloat = 40.0
    let kButtonCornerRadius: CGFloat = 4.0
    let kBottomSpacing: CGFloat = 60
    let kBottomSpacingWithoutApp: CGFloat = 90
    
    public var authorizeByAppHandler : (()->Void)?
    public var authorizeByLoginHandler : (()->Void)?
    public var eulaHandler : (()->Void)?
    let appAuthorizationButton = ASButtonNode()
    let loginAuthorizationButton = ASButtonNode()
    let eulaButton = ASButtonNode()
    let authorizationOverAppAvailable: Bool
    init(_ authorizationOverAppAvailable: Bool) {
        self.authorizationOverAppAvailable = authorizationOverAppAvailable
        super.init()
        self.addSubnode(appAuthorizationButton)
        self.addSubnode(loginAuthorizationButton)
        self.addSubnode(eulaButton)
        self.backgroundColor = UIColor(red: 130.0/255.0, green: 158.0/255.0, blue: 191.0/255.0, alpha: 1.0)
        appAuthorizationButton.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        loginAuthorizationButton.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        appAuthorizationButton.setAttributedTitle(NSAttributedString.init(string: "authorize_with_app".localized, attributes: TextStyles.authorizationButtonStyle()), for: .normal)
        loginAuthorizationButton.setAttributedTitle(NSAttributedString.init(string: "authorize_with_login".localized, attributes: TextStyles.authorizationButtonStyle()), for: .normal)
        eulaButton.setAttributedTitle(NSAttributedString.init(string: "eula_button".localized, attributes: TextStyles.eulaButtonStyle()), for: .normal)
        eulaButton.setAttributedTitle(NSAttributedString.init(string: "eula_button".localized, attributes: TextStyles.eulaHighlightedButtonStyle()), for: .highlighted)
        appAuthorizationButton.addTarget(self, action: #selector(authorizeByApp), forControlEvents: .touchUpInside)
        loginAuthorizationButton.addTarget(self, action: #selector(authorizeByLogin), forControlEvents: .touchUpInside)
        eulaButton.addTarget(self, action: #selector(eulaTapped), forControlEvents: .touchUpInside)
        for button in [appAuthorizationButton, loginAuthorizationButton, eulaButton] {
            button.style.height = ASDimensionMake(kAuthorizationButtonMargin)
            button.style.flexGrow = 1
            button.style.flexShrink = 1
        }
        eulaButton.style.height = ASDimensionMake(kAuthorizationButtonMargin/2)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var buttons = [ASLayoutElement]()
        if authorizationOverAppAvailable {
            buttons.append(appAuthorizationButton)
        }
        buttons.append(loginAuthorizationButton)
        buttons.append(eulaButton)
        let spacing = ASLayoutSpec()
        spacing.style.height = ASDimensionMake(authorizationOverAppAvailable ? kBottomSpacing : kBottomSpacingWithoutApp)
        buttons.append(spacing)
        
        var specs = [ASLayoutElement]()
        for button in buttons {
            let spec = ASStackLayoutSpec.init(direction: .horizontal, spacing: 0, justifyContent: .start, alignItems: .start, children: [button])
            if button.isEqual(eulaButton) {
                let s = ASInsetLayoutSpec(insets: UIEdgeInsetsMake(-20, 0, 0, 0), child: spec)
                specs.append(s)
            }
            else {
                specs.append(spec)
            }
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
    
    func eulaTapped() {
        if eulaHandler != nil {
            eulaHandler?()
        }
    }
}
