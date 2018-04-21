//
//  DemoChatViewController+ChatInputDelegate.swift
//  vk
//
//  Created by Jasf on 21.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

import UIKit
import Chatto
import ChattoAdditions

extension DemoChatViewController : ChatInputBarDelegate {
    
    func inputBarShouldBeginTextEditing(_ inputBar: ChatInputBar) -> Bool {
        return true
    }
    
    func inputBarDidBeginEditing(_ inputBar: ChatInputBar) {
        
    }
    
    func inputBarDidEndEditing(_ inputBar: ChatInputBar) {
        
    }
    
    @objc open func inputBarDidChangeText(_ inputBar: ChatInputBar) {
        
    }
    
    func inputBarSendButtonPressed(_ inputBar: ChatInputBar) {
        
    }
    
    func inputBar(_ inputBar: ChatInputBar, shouldFocusOnItem item: ChatInputItemProtocol) -> Bool {
        return true
    }
    
    func inputBar(_ inputBar: ChatInputBar, didReceiveFocusOnItem item: ChatInputItemProtocol) {
        
    }
    
    func inputBarDidShowPlaceholder(_ inputBar: ChatInputBar) {
        
    }
    
    func inputBarDidHidePlaceholder(_ inputBar: ChatInputBar) {
        
    }
    

}
