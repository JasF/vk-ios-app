//
//  DialogViewController.swift
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import NMessenger

open class DialogViewController: NMessengerViewController {
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    var nodeFactory: NodeFactory?
    var dialogService: DialogService?
    var userId: NSNumber?
    var handler: DialogHandlerProtocol?
    
    public init(handlersFactory:HandlersFactory?, nodeFactory:NodeFactory?, dialogService:DialogService?, userId:NSNumber?) {
        super.init(nibName:nil, bundle:nil)
        self.nodeFactory = nodeFactory!
        self.dialogService = dialogService!
        self.userId = userId!
        self.handler = handlersFactory!.dialogHandler()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
    }
}
