//
//  VideoPlayerNode.swift
//  vk
//
//  Created by Jasf on 05.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import AsyncDisplayKit
import WebKit

@objcMembers class VideoPlayerNode : ASDisplayNode {
    let video: Video
    var webView: WKWebView?
    init(_ video: Video) {
        self.video = video
        super.init();
        self.setViewBlock { [weak self] () -> UIView in
            self?.webView = WKWebView.init()
            if let urlString = video.player {
                (self?.webView)!.backgroundColor = UIColor.black
                let url = URL.init(string: urlString)!
                let request = URLRequest.init(url: url)
                (self?.webView)!.load(request)
            }
            return (self?.webView)!
        }
    }
}

