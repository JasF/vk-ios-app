//
//  CommentsServiceImpl.swift
//  vk
//
//  Created by Jasf on 01.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

import EasyMapping

@objc protocol CommentsService {
    func parseProfiles (_ aData: NSDictionary?) -> NSDictionary
    func parseComments (_ aData: NSDictionary?) -> NSArray
}

@objcMembers class CommentsServiceImpl : NSObject, CommentsService {
    public func parseProfiles(_ aData: NSDictionary?) -> NSDictionary {
        guard let data = aData else { return NSDictionary.init() }
        if !data.isKind(of: NSDictionary.self) {
            return NSDictionary.init()
        }
        guard let profiles = data["profiles"] as? NSArray else { return NSDictionary.init() }
        
        let results = EKMapper.arrayOfObjects(fromExternalRepresentation: profiles as! [Any], with: User.objectMapping())! as? [User]
        var users = [Int: NSObject]()
        guard let array = results else { return users as NSDictionary }
        for profile in array {
            users[profile.id] = profile
        }
        return users as NSDictionary
    }
    
    public func parseComments(_ aData: NSDictionary?) -> NSArray {
        guard let data = aData else { return [] as NSArray }
        let profiles = parseProfiles(aData)
        let commentsData = data["items"] as? NSArray
        let results = EKMapper.arrayOfObjects(fromExternalRepresentation: commentsData as! [Any], with: Comment.objectMapping())! as? [Comment]
        guard let comments = results else { return NSArray.init() }
        for comment in comments {
            let profile = profiles[comment.from_id] as? User
            comment.user = profile
        }
        return comments as NSArray
    }
}
