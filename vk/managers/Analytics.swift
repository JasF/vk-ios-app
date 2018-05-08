//
//  Analytics.swift
//  vk
//
//  Created by Jasf on 08.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import FBSDKCoreKit

@objc protocol Analytics {
    func logEvent(_ name: String)
}

@objc protocol PyAnalytics {
    func hello()
}

@objc protocol PyAnalyticsDelegate {
    func logEvent(_ name: String)
}

@objcMembers class AnalyticsImpl : NSObject {
    var handler : PyAnalytics? = nil
    init(_ handlersFactory: HandlersFactory) {
        super.init()
        handler = handlersFactory.analyticsHandler(withDelegate: self)
    }
}

extension AnalyticsImpl : Analytics, PyAnalyticsDelegate {
    func logEvent(_ name: String) {
        FBSDKAppEvents.logEvent(name)
    }
}
