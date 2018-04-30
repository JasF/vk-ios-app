//
//  CommentsPreloadModel.swift
//  vk
//
//  Created by Jasf on 30.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objcMembers class CommentsPreloadModel : NSObject {
    weak var cellNode: CommentsPreloadNode?
    var preload: Int
    var remaining: Int
    var post: WallPost?
    var video: Video?
    var photo: Photo?
    var loaded: Int
    init(_ preload: Int, remaining: Int) {
        self.preload = preload
        self.remaining = remaining
        self.loaded = 0
        super.init()
    }
    public func set(_ preload: Int, remaining: Int) {
        self.preload = preload
        self.remaining = remaining
        guard let node = self.cellNode else { return }
        node.set(preload, remaining:remaining)
    }
}
