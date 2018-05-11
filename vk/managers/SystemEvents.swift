//
//  SystemEvents.swift
//  vk
//
//  Created by Jasf on 11.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objc protocol SystemEvents {
    func applicationDidEnterBackground()
    func applicationWillEnterForeground()
    func applicationDidBecomeActive()
    func applicationWillResignActive()
    func applicationWillTerminate()
}

@objc protocol PySystemEvents {
    func applicationDidEnterBackground()
    func applicationWillEnterForeground()
    func applicationDidBecomeActive()
    func applicationWillResignActive()
    func applicationWillTerminate()
}

@objcMembers class SystemEventsImpl : NSObject {
    var handler : PySystemEvents? = nil
    init(_ handlersFactory: HandlersFactory) {
        super.init()
        handler = handlersFactory.systemEventsHandler()
    }
}

extension SystemEventsImpl : SystemEvents {
    func applicationDidEnterBackground() {
        guard let handler = self.handler else { return }
        handler.applicationDidEnterBackground()
    }
    func applicationWillEnterForeground() {
        guard let handler = self.handler else { return }
        handler.applicationWillEnterForeground()
    }
    func applicationDidBecomeActive() {
        guard let handler = self.handler else { return }
        handler.applicationDidBecomeActive()
    }
    func applicationWillResignActive() {
        guard let handler = self.handler else { return }
        handler.applicationWillResignActive()
    }
    func applicationWillTerminate() {
        guard let handler = self.handler else { return }
        handler.applicationWillTerminate()
    }
}
