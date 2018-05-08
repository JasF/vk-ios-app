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
}

@objcMembers class ModulesImpl : NSObject {
    let applicationAssembly: VKApplicationAssembly
    var analytics: Analytics? = nil
    init(_ applicationAssembly: VKApplicationAssembly) {
        self.applicationAssembly = applicationAssembly
        super.init()
    }
}

extension ModulesImpl : Modules {
    func performInitializationOfSubmodulesAfterPythonLoaded() {
        self.analytics = self.applicationAssembly.analytics()
    }
    func analyticsModule() -> Analytics? {
        return self.analytics
    }
}
