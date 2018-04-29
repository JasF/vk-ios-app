//
//  VideoPlayerViewModel.swift
//  vk
//
//  Created by Jasf on 29.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objc protocol VideoPlayerViewModel {
    func videoUrl() -> String?
}

@objcMembers class VideoPlayerViewModelImpl : NSObject {
    let video: Video?
    public init(_ video: Video?) {
        self.video = video
        super.init()
    }
}

extension VideoPlayerViewModelImpl : VideoPlayerViewModel {
    func videoUrl() -> String? {
        return video?.player
    }
}
