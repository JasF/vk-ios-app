/*
 The MIT License (MIT)

 Copyright (c) 2015-present Badoo Trading Limited.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import Foundation


class DemoChatDataSource: ChatDataSourceProtocol {
    var nextMessageId: Int = 0
    let preferredMaxWindowSize = 500

    var slidingWindow: SlidingDataSource<ChatItemProtocol>!
    init(count: Int, pageSize: Int) {
        self.slidingWindow = SlidingDataSource(count: count, pageSize: pageSize) { [weak self] (count:Int) -> [ChatItemProtocol] in
            guard let sSelf = self else { return [DemoChatMessageFactory.makeRandomMessage("")] }
            defer { sSelf.nextMessageId += 1 }
            var array = [ChatItemProtocol]()
            for _ in 0...count {
                array.append(DemoChatMessageFactory.makeRandomMessage("\(sSelf.nextMessageId)"))
            }
            return array
        }
    }

    init(pageSize: Int, callback: ((_ count: Int) -> [ChatItemProtocol])?) {
        /*
        self.slidingWindow = SlidingDataSource(count: 50, pageSize: pageSize) { [weak self] (count:Int) -> [ChatItemProtocol] in
            guard let sSelf = self else { return [DemoChatMessageFactory.makeRandomMessage("")] }
            defer { sSelf.nextMessageId += 1 }
            var array = [ChatItemProtocol]()
            for _ in 0...count {
                array.append(DemoChatMessageFactory.makeRandomMessage("\(sSelf.nextMessageId)"))
            }
            return array
        }
        */
        
        self.slidingWindow = SlidingDataSource(count: 0, pageSize: pageSize) { [] (count:Int) -> [ChatItemProtocol] in
            return callback!(count)
        }
 
    }

    lazy var messageSender: DemoChatMessageSender = {
        let sender = DemoChatMessageSender()
        sender.onSendMessage = { [weak self] (message, completion) in
            guard let sSelf = self else { return }
            sSelf.delegate?.repeatSendMessage(message) { (success) in
                completion(success)
            }
        }
        sender.onMessageChanged = { [weak self] (message) in
            guard let sSelf = self else { return }
            sSelf.delegate?.chatDataSourceDidUpdate(sSelf)
        }
        return sender
    }()

    var hasMoreNext: Bool {
        return self.slidingWindow.hasMore()
    }
    
    private var batchFetchContentCallback: (() -> Void)?
    open func setBatchFetchContent(callback: (() -> Void)?) {
        self.batchFetchContentCallback = callback
    }

    var hasMorePrevious: Bool {
        let result = self.slidingWindow.hasPrevious()
        self.batchFetchContentCallback?()
        return result
    }

    var chatItems: [ChatItemProtocol] {
        return self.slidingWindow.itemsInWindow
    }

    weak var delegate: ChatDataSourceDelegateProtocol?

    func loadNext() {
        self.slidingWindow.loadNext()
        self.slidingWindow.adjustWindow(focusPosition: 1, maxWindowSize: self.preferredMaxWindowSize)
        self.delegate?.chatDataSourceDidUpdate(self, updateType: .pagination)
    }

    func loadPrevious(count:Int) {
        self.slidingWindow.loadPrevious(count:count)
        self.slidingWindow.adjustWindow(focusPosition: 0, maxWindowSize: self.preferredMaxWindowSize)
        self.delegate?.chatDataSourceDidUpdate(self, updateType: .pagination)
    }
    
    func loadPrevious() {
        self.slidingWindow.loadPrevious()
        self.slidingWindow.adjustWindow(focusPosition: 0, maxWindowSize: self.preferredMaxWindowSize)
        self.delegate?.chatDataSourceDidUpdate(self, updateType: .pagination)
    }

    func updateDatasource() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.delegate?.chatDataSourceDidUpdate(self, updateType: .normal)
        })
    }
    
    public func handleMessageFlagsChanged(_ message: Message!) {
        let items = self.slidingWindow.getItems()
        for item in items as! [DemoMessageModelProtocol] {
            if item.externalId == message.identifier {
                NSLog("found needed item \(item.externalId) text \(message.body)")
                item.setReadState(message.read_state)
                updateDatasource()
                break
            }
        }
    }
    
    func markAsReaded(_ messageId: Int, _ isIncoming: Bool, _ tableNode: ASTableNode) {
        var indexPatches = [IndexPath]()
        let items = self.slidingWindow.getItems()
        var ignoredItems = 0
        for item in items as! [DemoMessageModelProtocol] {
            if ignoredItems > 5 {
                break
            }
            if item.externalId <= messageId && item.isIncoming == isIncoming {
                item.setReadState(1)
                guard let viewModel = item.viewModel else { continue }
                guard let node = viewModel.node else { continue }
                guard let indexPath = tableNode.indexPath(for: node) else { continue }
                indexPatches.append(indexPath)
            }
            else {
                ignoredItems = ignoredItems + 1
            }
        }
        if indexPatches.count > 0 {
            DispatchQueue.main.async(execute: { () -> Void in
                tableNode .reloadRows(at: indexPatches, with: .none)
            })
        }
    }
    
    public func handleMessages(inReaded messageId: Int, _ tableNode: ASTableNode) {
        markAsReaded(messageId, true, tableNode)
    }
    
    public func handleMessagesOutReaded(_ messageId: Int, _ tableNode: ASTableNode) {
        markAsReaded(messageId, false, tableNode)
    }
    
    func addIncomingTextMessage(_ message: Message?) {
        self.nextMessageId += 1
        let uid = "\(self.nextMessageId)"
        let model = DemoChatMessageFactory.makeTextMessage(uid, message: message)
        self.slidingWindow.insertItem(model, position: .top)
        self.delegate?.chatDataSourceDidUpdate(self)
    }
    
    func handleEditMessage(_ message: Message!) {
        let items = self.slidingWindow.getItems()
        for item in items as! [DemoMessageModelProtocol] {
            if item.externalId == message.identifier {
                if let textItem = item as? DemoTextMessageModel {
                    textItem.text = message.body
                    item.message = message
                    updateDatasource()
                    break
                }
            }
        }
    }
    
    func addTextMessage(_ text: String) {
        self.nextMessageId += 1
        let uid = "\(self.nextMessageId)"
        let message = DemoChatMessageFactory.makeTextMessage(uid, text: text, isIncoming: false, readState: 0, externalId: 0, sending: true)
        self.delegate?.willSendTextMessage(text: text, uid:uid, message: message)
        //self.messageSender.sendMessage(message)
        self.slidingWindow.insertItem(message, position: .top)
        self.delegate?.chatDataSourceDidUpdate(self)
    }

    func addPhotoMessage(_ image: UIImage) {
        self.nextMessageId += 1
        let uid = "\(self.nextMessageId)"
        let message = DemoChatMessageFactory.makePhotoMessage(uid, image: image, size: image.size, isIncoming: false)
        self.messageSender.sendMessage(message)
        self.slidingWindow.insertItem(message, position: .bottom)
        self.delegate?.chatDataSourceDidUpdate(self)
    }

    func adjustNumberOfMessages(preferredMaxCount: Int?, focusPosition: Double, completion:(_ didAdjust: Bool) -> Void) {
        let didAdjust = self.slidingWindow.adjustWindow(focusPosition: focusPosition, maxWindowSize: preferredMaxCount ?? self.preferredMaxWindowSize)
        completion(didAdjust)
    }
}
