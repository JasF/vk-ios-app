//
//  CreatePostViewModel.swift
//  vk
//
//  Created by Jasf on 01.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objc protocol CreatePostViewModel {
    func send(_ text: String)
}

@objc protocol PyCreatePostViewModel {
    func send(_ text: String)
}

@objcMembers class CreatePostViewModelImpl : NSObject {
    var handler: PyCreatePostViewModel
    public init(_ handlersFactory: HandlersFactory) {
        handler = handlersFactory.createPostViewModelHandler()
        super.init()
    }
}

extension CreatePostViewModelImpl : CreatePostViewModel {
    func send(_ text: String) {
        DispatchQueue.global(qos: .background).async {
            self.handler.send(text)
        }
    }
}
