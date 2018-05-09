//
//  DialogViewController.swift
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import UIKit


import CocoaLumberjack

class DialogViewController: DemoChatViewController, DialogScreenViewModelDelegate {
    var viewModel: DialogScreenViewModel?
    var messages: Array<Message>?
    var secondMessages: Array<Message>?
    var scrollToBottom: Bool
    
    @objc init(viewModel:DialogScreenViewModel?, nodeFactory:NodeFactory) {
        self.scrollToBottom = false
        super.init(nodeFactory)
        self.viewModel = viewModel!
        self.viewModel!.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var mDataSource: DemoChatDataSource!
    
    override func viewDidLoad() {
        self.mDataSource = DemoChatDataSource(pageSize: 20) { [weak self] (count:Int) -> [ChatItemProtocol] in
            guard let sSelf = self else { return [] }
            var resultArray = [ChatItemProtocol]()
            for message in sSelf.messages! {
                sSelf.mDataSource?.nextMessageId += 1
                let item = DemoChatMessageFactory.makeTextMessage("\(sSelf.mDataSource?.nextMessageId)", message: message)
                resultArray.append(item)
            }
            sSelf.messages?.removeAll()
            return resultArray
        }
        self.mDataSource.setBatchFetchContent() { [weak self] () -> Void in
            //NSLog("! needs batch fetch content");
            //self?.batchFetchContent()
        }
        self.dataSource = self.mDataSource
        super.viewDidLoad()
        
        let button = UIBarButtonItem(
            title: "Show typing",
            style: .plain,
            target: self,
            action: #selector(showTypingCell)
        )
        self.navigationItem.rightBarButtonItem = button
    }
    
    @objc
    private func showTypingCell() {
        NSLog("Deprecated");
    }
    
    var updating: Bool?
    
    func tableNode(_ tableNode: ASTableNode, willBeginBatchFetchWith context: ASBatchContext) {
        if self.updating == true || self.initiallyGetted == false {
            context.completeBatchFetching(true)
            return
        }
        let message = self.secondMessages?.last
        if message != nil {
            self.updating = true
            
            self.viewModel?.getMessagesWithOffset(0, startMessageId: Int(message!.identifier)) {messages in
                context.completeBatchFetching(true)
                if messages == nil {
                    return
                }
                self.updating = false
                if let array = messages! as NSArray as? [Message] {
                    self.secondMessages?.append(contentsOf: array)
                    self.messages?.append(contentsOf: array)
                }
                self.mDataSource.loadPrevious(count:self.messages!.count)
            }
            
        }
    }
    
    @objc override open func tableNode(_ tableNode: ASTableNode, willDisplayRowWith node: ASCellNode) {
        if !node.isKind(of: ChatBaseNodeCell.self) {
            return
        }
        guard let indexPath = tableNode.indexPath(for: node) else { return }
        let presenter = self.presenterForIndexPath(indexPath)
        let messageModel = presenter.getMessageModel() as! MessageModelProtocol?
        if messageModel != nil {
            if messageModel?.readState == 0 {
                let identifier = messageModel?.externalId
                let isIncoming = messageModel?.isIncoming
                self.viewModel?.willDisplayUnreadedMessage(withIdentifier: identifier!, isOut: isIncoming! ? 0 : 1)
            }
        }
        super.tableNode(tableNode, willDisplayRowWith: node)
    }
    
    var initiallyGetted = false
    override open func viewWillAppear(_ animated: Bool ) {
        super.viewWillAppear(animated)
        
        if initiallyGetted == true {
            return
        }
        self.updating = true
        self.viewModel?.getMessagesWithOffset(0) {[weak self] messages in
            if messages == nil {
                return
            }
            self?.updating = false
            self?.initiallyGetted = true
            if var array = messages! as NSArray as? [Message] {
                self?.messages = array
                self?.secondMessages = array
                self?.scrollToBottom = true
                self?.mDataSource.loadPrevious(count:array.count)
            }
        }
    }
    
    override func willSendTextMessage(text: String?, uid: String?, message: Any?) {
        NSLog("will send text message: \(String(describing: text))");
        if let msg = message as? DemoMessageModelProtocol {
            self.scrollToBottom(animated: true)
            sendMessage(text, msg, completion:{ (success) in
                self.dataSource.messageSender.updateMessage(msg, success)
            })
        }
    }
    
    func sendMessage(_ text: String?, _ msg: DemoMessageModelProtocol, completion: @escaping (Bool) -> Void) {
        self.viewModel?.sendTextMessage(text) { messageId in
            msg.setExternalId(messageId)
            completion((messageId > 0) ? true : false )
        }
    }
    
    override func repeatSendMessage(_ message: ChatItemProtocol, completion: @escaping (Bool) -> Void) {
        if let msg = message as? DemoTextMessageModel {
            sendMessage(msg.text, msg) { success in
                completion(success)
            }
        }
    }
    
    override func needsScrollToBottom() -> Bool {
        if self.scrollToBottom == true {
            self.scrollToBottom = false
            return true
        }
        return false
    }
    
    //pragma mark - DialogScreenViewModelDelegate
    func handleIncomingMessage(_ message: Message?) {
        self.setTypingCellEnabled(false)
        self.mDataSource?.addIncomingTextMessage(message)
    }
    
    func handleEdit(_ message: Message!) {
        self.mDataSource?.handleEditMessage(message)
    }
    
    func handleMessageDelete(_ messageId: NSNumber!) {
        self.mDataSource?.handleMessageDelete(messageId.intValue)
    }
    
    func handleMessageFlagsChanged(_ message: Message!) {
        self.mDataSource?.handleMessageFlagsChanged(message)
    }
    
    func handleTyping(_ userId: Int, end: Bool) {
        NSLog("typing: \(userId)");
        self.setTypingCellEnabled(!end)
    }
    
    func handleMessages(inReaded messageId: Int) {
        NSLog("inReaded: \(messageId)")
        self.mDataSource?.handleMessages(inReaded: messageId, self.tableNode)
    }
    
    func handleMessagesOutReaded(_ messageId: Int) {
        NSLog("handleMessagesOutReaded: \(messageId)")
        self.mDataSource?.handleMessagesOutReaded(messageId, self.tableNode)
    }
    
    // ChatInputBarDelegate
    override func inputBarDidChangeText(_ text: String) {
        self.viewModel?.inputBarDidChangeText(text)
    }
    
    override func didTappedOnPhoto(_ message: Message, index: Int) {
        self.viewModel?.userDidTappedOnPhoto(with: index, message: message)
    }
    
    override func didTappedOnVideo(_ message: Message, video: Video) {
        self.viewModel?.userDidTapped(on: video, message: message)
    }
}

@objcMembers class DialogViewControllerAllocator : NSObject {
    var viewController: DialogViewController?
    @objc init(viewModel:DialogScreenViewModel?, nodeFactory:NodeFactory?) {
        viewController = DialogViewController.init(viewModel:viewModel, nodeFactory:nodeFactory!)
        super.init()
    }
    public func getViewController() -> Any? {
        return viewController
    }
}

