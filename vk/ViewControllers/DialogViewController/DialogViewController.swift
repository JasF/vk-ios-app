//
//  DialogViewController.swift
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import UIKit
import Chatto

class DialogViewController: DemoChatViewController, DialogScreenViewModelDelegate {
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var nodeFactory: NodeFactory?
    var viewModel: DialogScreenViewModel?
    var messages: Array<Message>?
    var secondMessages: Array<Message>?
    
    @objc init(viewModel:DialogScreenViewModel?, nodeFactory:NodeFactory?) {
        super.init(nibName:nil, bundle:nil)
        self.viewModel = viewModel!
        self.nodeFactory = nodeFactory!
        self.viewModel!.delegate = self
    }
    
    deinit {
        NSLog("dialogvc deinit");
    }
    
    var mDataSource: DemoChatDataSource!
    
    override func viewDidLoad() {
        self.mDataSource = DemoChatDataSource(pageSize: 20) { [weak self] (count:Int) -> [ChatItemProtocol] in
            guard let sSelf = self else { return [] }
            var resultArray = [ChatItemProtocol]()
            for message in sSelf.messages! {
                sSelf.mDataSource?.nextMessageId += 1
                let item = DemoChatMessageFactory.makeTextMessage("\(sSelf.mDataSource?.nextMessageId)", text: message.body!, isIncoming: message.isOut == 0 ?true:false)
                resultArray.append(item)
            }
            sSelf.messages?.removeAll()
            return resultArray
        }
        self.mDataSource.setBatchFetchContent() { () -> Void in
            self.batchFetchContent()
        }
        //self.dataSource = self.mDataSource
        super.viewDidLoad()
        
        let button = UIBarButtonItem(
            title: "Add message",
            style: .plain,
            target: self,
            action: #selector(addRandomMessage)
        )
        self.navigationItem.rightBarButtonItem = button
    }
    
    @objc
    private func addRandomMessage() {
        self.dataSource.addRandomIncomingMessage()
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
 
    
    override open func viewWillAppear(_ animated: Bool ) {
        super.viewWillAppear(animated)
        
        self.viewModel?.getMessagesWithOffset(0) {messages in
            if messages == nil {
                return
            }
            if let array = messages! as NSArray as? [Message] {
                self.messages = array
                self.secondMessages = array
                self.mDataSource.loadPrevious(count:array.count)
                let deadlineTime = DispatchTime.now() + .milliseconds(500)
                DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                    self.scrollToBottom(animated: false)
                }
            }
        }
    }
    
    override func willSendTextMessage(message: String?) {
        NSLog("will send text message: \(String(describing: message))");
        self.viewModel?.sendTextMessage(message)
    }
    
    func handleIncomingMessage(_ message: String?, userId: NSNumber?, timestamp: NSNumber?) {
        self.mDataSource?.addIncomingTextMessage(message!)
    }
}
