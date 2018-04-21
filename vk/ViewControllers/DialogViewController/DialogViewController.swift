//
//  DialogViewController.swift
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import UIKit
import Chatto
import ChattoAdditions

class DialogViewController: DemoChatViewController, DialogScreenViewModelDelegate {
    public required init?(coder aDecoder: NSCoder) {
        self.scrollToBottom = false
        super.init(coder: aDecoder)
    }
    
    var nodeFactory: NodeFactory?
    var viewModel: DialogScreenViewModel?
    var messages: Array<Message>?
    var secondMessages: Array<Message>?
    var scrollToBottom: Bool
    
    @objc init(viewModel:DialogScreenViewModel?, nodeFactory:NodeFactory?) {
        self.scrollToBottom = false
        super.init(nibName:nil, bundle:nil)
        self.viewModel = viewModel!
        self.nodeFactory = nodeFactory!
        self.viewModel!.delegate = self
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
            self?.batchFetchContent()
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
    public func batchFetchContent() {
        if self.updating == true {
            return
        }
        let message = self.secondMessages?.last
        if message != nil {
            self.updating = true
            
            self.viewModel?.getMessagesWithOffset(0, startMessageId: Int(message!.identifier)) {messages in
                print("hello response!")
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
        NSLog("begin chat batch fetch content");
    }
 
    @objc(collectionView:willDisplayCell:forItemAtIndexPath:)
    override open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Here indexPath should always referer to updated data source.
        NSLog("willDsiplay: \(indexPath)")
        let presenter = self.presenterForIndexPath(indexPath)
        let messageModel = presenter.getMessageModel() as! MessageModelProtocol?
        if messageModel != nil {
            if messageModel?.readState == 0 {
                let identifier = messageModel?.externalId
                let isIncoming = messageModel?.isIncoming
                self.viewModel?.willDisplayUnreadedMessage(withIdentifier: identifier!, isOut: isIncoming! ? 0 : 1)
            }
        }
        super.collectionView(collectionView, willDisplay: cell, forItemAt: indexPath)
    }
    
    override open func viewWillAppear(_ animated: Bool ) {
        super.viewWillAppear(animated)
        
        self.viewModel?.getMessagesWithOffset(0) {messages in
            if messages == nil {
                return
            }
            if let array = messages! as NSArray as? [Message] {
                self.messages = array
                self.secondMessages = array
                self.scrollToBottom = true
                self.mDataSource.loadPrevious(count:array.count)
            }
        }
    }
    
    override func willSendTextMessage(text: String?, uid: String?, message: Any?) {
        NSLog("will send text message: \(String(describing: text))");
        let msg = message as! DemoMessageModelProtocol?
        self.scrollToBottom(animated: true)
        self.viewModel?.sendTextMessage(text) { messageId in
            NSLog("messageId is: \(messageId)");
            msg?.setExternalId(messageId)
            NSLog("!");
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
    
    func handleMessageFlagsChanged(_ message: Message!) {
        self.mDataSource?.handleMessageFlagsChanged(message)
    }
    
    func handleTyping(_ userId: Int, end: Bool) {
        self.setTypingCellEnabled(!end)
    }
}
