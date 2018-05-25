//
//  BlackListService.swift
//  Oxy Feed
//
//  Created by Jasf on 25.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objc protocol BlackListService {
    func usersFromResponse(_ response: Dictionary<String, Any>) -> [Any]
}

@objcMembers class BlackListServiceImpl : NSObject, BlackListService {
    func usersFromResponse(_ response: Dictionary<String, Any>) -> [Any] {
        if let usersData = response["items"] as? [Any] {
            if let results = EKMapper.arrayOfObjects(fromExternalRepresentation: usersData, with: User.objectMapping()) {
                return results
            }
        }
        return []
    }
}
