//
//  NSDictionary+Utils.swift
//  Oxy Feed
//
//  Created by Jasf on 27.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objc extension NSDictionary {
    public func utils_getError() -> NSError? {
        if let error = self["error"] as? NSDictionary {
            if let type = error["type"] as? String {
                if type == "connection" {
                    return NSError.utils_connectivityError(1)
                }
            }
        }
        return nil;
    }
}
