//
//  WallUserMessageNode.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import NMessenger


@objc protocol WallUserMessageNodeDelegate {
    func messageButtonTapped()
    func friendButtonTapped(_ completion: (Int) -> Void)
}

@objcMembers class WallUserMessageNode : ASCellNode {
    var user: User? = nil
    let leftButton: ASButtonNode! = ASButtonNode()
    let rightButton: ASButtonNode! = ASButtonNode()
    var delegate: WallUserMessageNodeDelegate? = nil
    init(_ user: User?) {
        super.init()
        self.user = user
        self.addSubnode(leftButton)
        self.addSubnode(rightButton)
        leftButton.style.height = ASDimensionMake(30)
        leftButton.cornerRadius = leftButton.style.height.value/2
        leftButton.setAttributedTitle(NSAttributedString.init(string: "send_message".localized, attributes: TextStyles.buttonTextStyle()), for: .normal)
        leftButton.backgroundColor = TextStyles.buttonColor()
        leftButton.addTarget(self, action: #selector(leftButtonTapped), forControlEvents: .touchUpInside)
        rightButton.style.height = leftButton.style.height
        rightButton.cornerRadius = leftButton.style.height.value/2
        updateFriendStatus()
        rightButton.addTarget(self, action: #selector(rightButtonTapped), forControlEvents: .touchUpInside)
        
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        leftButton.style.flexGrow = 1
        rightButton.style.flexGrow = 1
        let spec = ASStackLayoutSpec.init(direction: .horizontal, spacing: 8, justifyContent: .start, alignItems: .center, children: [leftButton, rightButton])
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(8,8,8,8), child:spec)
    }
    
    func leftButtonTapped() {
        self.delegate?.messageButtonTapped()
    }
    
    func rightButtonTapped() {
        let is_member = user?.is_member
        let you_are_send_request = user?.you_are_send_request
        self.delegate?.friendButtonTapped() { [weak self] response in
            if (self?.isGroup())! {
                if response == 1 {
                    if you_are_send_request == 1 {
                        user?.you_are_send_request = 0;
                    }
                    else if is_member == 0 {
                        if ((user?.is_closed) != nil) {
                            user?.you_are_send_request = 1;
                        }
                        else {
                            user?.is_member = 1
                        }
                    }
                    else {
                        user?.is_member = 0
                    }
                }
            }
            else {
                var valueForWrite = self?.user?.friend_status
                /* response
                 1 — заявка на добавление данного пользователя в друзья отправлена;
                 2 — заявка на добавление в друзья от данного пользователя одобрена;
                 4 — повторная отправка заявки.
                 */
                switch response {
                case 5: valueForWrite = 2; break // удален друг
                case 0: valueForWrite = 0; self?.user?.is_friend = 0; break
                case 1: valueForWrite = 1; break
                case 2: valueForWrite = 3; self?.user?.is_friend = 1; break
                case 4: valueForWrite = 1; break
                default: break
                }
                self?.user?.friend_status = valueForWrite!
            }
            self?.updateFriendStatus()
        }
    }
    
    func joinString() -> String {
        if user?.type == "page" {
            return "page_subscribe"
        }
        else if user?.type == "group" {
            if user?.is_closed == 1 {
                return "group_add_request"
            }
            return "group_enter"
        }
        else if user?.type == "event" {
            return ""
        }
        return "";
    }
    
    func leaveString() -> String {
        if user?.type == "page" {
            return "page_unsubscribe"
        }
        else if user?.type == "group" {
            if user?.you_are_send_request == 1 {
                return "group_you_are_send_request"
            }
            return "group_leave"
        }
        assert(false, "unknown condition")
        return "is_your_friend";
    }
    
    func isGroup() -> Bool {
        return (user?.isGroup())!
    }
    
    func updateFriendStatus() {
        var rightButtonBackgroundColor = TextStyles.buttonColor()
        var rightAttrString: NSAttributedString!
        if isGroup() {
            if user?.is_member == 1 || user?.you_are_send_request == 1 {
                rightButtonBackgroundColor = TextStyles.buttonPassiveColor()
                rightAttrString = NSAttributedString.init(string: leaveString().localized, attributes: TextStyles.buttonPassiveTextStyle())
            }
            else {
                rightAttrString = NSAttributedString.init(string: joinString().localized, attributes: TextStyles.buttonTextStyle())
            }
        }
        else {
            /* user?.friend_status
             0 – пользователь не является другом,
             1 – отправлена заявка/подписка пользователю,
             2 – имеется входящая заявка/подписка от пользователя,
             3 – пользователь является другом;
             */
            if user?.friend_status == 0 {
                rightAttrString = NSAttributedString.init(string: joinString().localized, attributes: TextStyles.buttonTextStyle())
            }
            else {
                let string = (user?.friend_status == 2) ? "subscribed_to_you" : ((user?.friend_status == 1) ? "you_are_subscribed" : "is_your_friend")
                rightButtonBackgroundColor = TextStyles.buttonPassiveColor()
                rightAttrString = NSAttributedString.init(string: string.localized, attributes: TextStyles.buttonPassiveTextStyle())
            }
        }
        rightButton.backgroundColor = rightButtonBackgroundColor
        rightButton.setAttributedTitle(rightAttrString, for: .normal)
        self.setNeedsLayout()
        self.setNeedsDisplay()
        rightButton.setNeedsDisplay()
    }
}



