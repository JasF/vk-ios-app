//
//  NSError+Utils.swift
//  Oxy Feed
//
//  Created by Jasf on 27.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

let kConnectivityDomain = "ConnectivityDomain"

@objc extension NSError {
    class public func utils_connectivityError(_ code: Int) -> NSError {
        return NSError.init(domain: kConnectivityDomain, code: code, userInfo: nil)
    }
    public func utils_isConnectivityError() -> Bool {
        return (self.domain == kConnectivityDomain) ? true : false
    }
}
