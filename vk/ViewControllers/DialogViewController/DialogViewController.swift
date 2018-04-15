//
//  DialogViewController.swift
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import UIKit

class DialogViewController: DemoChatViewController {
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var nodeFactory: NodeFactory?
    var dialogService: DialogService?
    var userId: NSNumber?
    var handler: DialogHandlerProtocol?
    var messages: Array<Message>?
    
    @objc init(handlersFactory:HandlersFactory?, nodeFactory:NodeFactory?, dialogService:DialogService?, userId:NSNumber?) {
        super.init(nibName:nil, bundle:nil)
        self.nodeFactory = nodeFactory!
        self.dialogService = dialogService!
        self.userId = userId!
    }
    
    override func viewDidLoad() {
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
    /*
    public func batchFetchContent() {
        let message = self.messages?.last
        if message != nil {
            self.dialogService?.getMessagesWithOffset(0, userId: Int(self.userId!), startMessageId: Int(message!.identifier)) {messages in
                print("hello response!")
                if let array = messages! as NSArray as? [Message] {
                    self.messages?.append(contentsOf: array)
                    var messagesArray = [GeneralMessengerCell]()
                    for data in array.reversed() {
                        let message = self.createTextMessage(data.body, isIncomingMessage: data.isOut == 0 ?true:false)
                        messagesArray.append(message)
                    }
                    self.messengerView.endBatchFetchWithMessages(messagesArray)
                }
                
            }
        }
        NSLog("begin chat batch fetch content");
    }
 */
    
    override open func viewWillAppear(_ animated: Bool ) {
        super.viewWillAppear(animated)
        
        self.dialogService?.getMessagesWithOffset(0, userId: Int(self.userId!)) {messages in
            if let array = messages! as NSArray as? [Message] {
                self.messages = array
                for data in self.messages!.reversed() {
                    //self.sendText(data.body, isIncomingMessage: data.isOut == 0 ?true:false)
                    //print(data);
                }
            }
        }
    }
}
