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



public protocol DemoMessageViewModelProtocol {
    var messageModel: DemoMessageModelProtocol { get }
}

protocol BaseMessageHandlerDelegate: class {
    func didTappedOnPhoto(_ message: Message, index: Int)
    func didTappedOnVideo(_ message: Message, video: Video)
}

class BaseMessageHandler {

    private let messageSender: DemoChatMessageSender
    private let messagesSelector: MessagesSelectorProtocol
    weak var delegate: BaseMessageHandlerDelegate? = nil

    init(messageSender: DemoChatMessageSender, messagesSelector: MessagesSelectorProtocol, delegate: BaseMessageHandlerDelegate) {
        self.messageSender = messageSender
        self.messagesSelector = messagesSelector
        self.delegate = delegate
    }
    func userDidTapOnFailIcon(viewModel: DemoMessageViewModelProtocol) {
        print("userDidTapOnFailIcon")
        self.messageSender.sendMessage(viewModel.messageModel)
    }

    func userDidTappedOnPhoto(viewModel: DemoMessageViewModelProtocol, index: Int) {
        if let delegate = self.delegate {
            if let message = viewModel.messageModel.message {
                delegate.didTappedOnPhoto(message, index: index)
            }
        }
    }
    
    func userDidTappedOnVideo(viewModel: DemoMessageViewModelProtocol, video: Video) {
        if let delegate = self.delegate {
            if let message = viewModel.messageModel.message {
                delegate.didTappedOnVideo(message, video: video)
            }
        }
    }
    
    func userDidTapOnAvatar(viewModel: MessageViewModelProtocol) {
        print("userDidTapOnAvatar")
    }

    func userDidTapOnBubble(viewModel: DemoMessageViewModelProtocol) {
        print("userDidTapOnBubble")
    }

    func userDidBeginLongPressOnBubble(viewModel: DemoMessageViewModelProtocol) {
        print("userDidBeginLongPressOnBubble")
    }

    func userDidEndLongPressOnBubble(viewModel: DemoMessageViewModelProtocol) {
        print("userDidEndLongPressOnBubble")
    }

    func userDidSelectMessage(viewModel: DemoMessageViewModelProtocol) {
        print("userDidSelectMessage")
        self.messagesSelector.selectMessage(viewModel.messageModel)
    }

    func userDidDeselectMessage(viewModel: DemoMessageViewModelProtocol) {
        print("userDidDeselectMessage")
        self.messagesSelector.deselectMessage(viewModel.messageModel)
    }
}
