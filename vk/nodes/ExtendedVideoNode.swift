//
//  ExtendedVideoNode.swift
//  vk
//
//  Created by Jasf on 05.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import AsyncDisplayKit

@objcMembers class VideoModel : NSObject {
    var video: Video?
    init(_ video: Video) {
        self.video = video
        super.init()
    }
}

@objcMembers class ExtendedVideoNode : PostBaseNode {
    let video: Video
    let videoPlayer: VideoPlayerNode
    let titleNode = ASTextNode()
    let textNode = PostTextNode()
    let timeNode = ASTextNode()
    let viewsNode = ASTextNode()
    init(_ video: Video) {
        self.video = video
        self.videoPlayer = VideoPlayerNode(video)
        var likesCount = 0
        var repostsCount = 0
        var liked = false
        var reposted = false
        var comments = 0
        if let likes = video.likes {
            likesCount = likes.count
            liked = likes.user_likes
        }
        if let reposts = video.reposts {
            repostsCount = reposts.count
            reposted = reposts.user_reposted
        }
        comments = video.comments
        super.init(embedded: false,
                   likesCount: likesCount,
                   liked: liked,
                   repostsCount: repostsCount,
                   reposted:reposted,
                   commentsCount:comments)
        self.item = video
        self.addSubnode(videoPlayer)
        self.addSubnode(titleNode)
        self.addSubnode(timeNode)
        self.addSubnode(viewsNode)
        self.addSubnode(textNode)
        
        titleNode.attributedText = NSAttributedString.init(string: (video.title != nil) ? video.title : "", attributes: TextStyles.nameStyle())
        let date = NSDate.init(timeIntervalSince1970: TimeInterval(video.date))
        timeNode.attributedText = NSAttributedString.init(string: date.utils_longDayDifferenceFromNow(), attributes: TextStyles.timeStyle())
        viewsNode.attributedText = NSAttributedString.init(string: "\("video_views".localized): \(video.views)", attributes: TextStyles.timeStyle())
        textNode.attributedText = NSAttributedString.init(string: video.videoDescription, attributes: TextStyles.titleStyle())
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var ratio : CGFloat = 240.0/320.0;
        if Double(video.height) > 0.0 && Double(video.width) > 0.0 {
            ratio = CGFloat(video.height)/CGFloat(video.width)
        }
        let spec = ASRatioLayoutSpec.init(ratio: ratio, child: videoPlayer)
        let titleSpec = ASStackLayoutSpec.init(direction: .horizontal, spacing: 0, justifyContent: .start, alignItems: .stretch, children: [titleNode])
        let descpriptionSpec = ASStackLayoutSpec.init(direction: .horizontal, spacing: 0, justifyContent: .start, alignItems: .stretch, children: [textNode])
        titleNode.style.flexShrink = 1
        titleSpec.style.flexShrink = 1
        descpriptionSpec.style.flexShrink = 1
        textNode.style.flexShrink = 1
        var array: [ASLayoutElement] = [spec, titleSpec, timeNode, viewsNode, descpriptionSpec]
        let stack = self.controlsStack()
        if stack != nil {
            stack?.style.spacingBefore = 12
            stack?.style.spacingAfter = 12
            array.append(stack!)
        }
        let nameStack = ASStackLayoutSpec.init(direction: .vertical, spacing: kMargin, justifyContent: .start, alignItems: .stretch, children: array)
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(kMargin, kMargin, kMargin, kMargin), child: nameStack)
    }
}

