//
//  Modules.swift
//  vk
//
//  Created by Jasf on 08.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objc protocol Modules {
    func performInitializationOfSubmodulesAfterPythonLoaded()
    func analyticsModule() -> Analytics?
    var systemEvents: SystemEvents? { get }
}

@objcMembers class ModulesImpl : NSObject {
    let applicationAssembly: VKApplicationAssembly
    var analytics: Analytics? = nil
    var systemEvents: SystemEvents? = nil
    init(_ applicationAssembly: VKApplicationAssembly) {
        self.applicationAssembly = applicationAssembly
        super.init()
    }
}

extension ModulesImpl : Modules {
    func performInitializationOfSubmodulesAfterPythonLoaded() {
        self.analytics = self.applicationAssembly.analytics()
        self.systemEvents = self.applicationAssembly.systemEvents()
    }
    func analyticsModule() -> Analytics? {
        return self.analytics
    }
}
