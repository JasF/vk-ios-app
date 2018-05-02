//
//  CreatePostViewModel.swift
//  vk
//
//  Created by Jasf on 01.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objc protocol CreatePostViewModel {
    func send(_ text: String, completion: ((Bool) -> Void)?)
}

@objc protocol PyCreatePostViewModel {
    func createPost(_ text: String) -> NSNumber?
}

@objcMembers class CreatePostViewModelImpl : NSObject {
    var handler: PyCreatePostViewModel
    public init(_ handlersFactory: HandlersFactory, ownerId: NSNumber?) {
        handler = handlersFactory.createPostViewModelHandler(ownerId as! Int)
        super.init()
    }
}

extension CreatePostViewModelImpl : CreatePostViewModel {
    func send(_ text: String, completion: ((Bool) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            let postIdNum = self.handler.createPost(text)
            var postId = 0
            if (postIdNum?.isKind(of: NSNumber.self))! {
                postId = (postIdNum?.intValue)!
            }
            DispatchQueue.main.async {
                if completion != nil {
                    completion?(postId > 0 ? true : false)
                }
            }
        }
    }
}
