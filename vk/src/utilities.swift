//
//  utilities.swift
//  vk
//
//  Created by Jasf on 04.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

func dispatch_python(_ callback: @escaping ()->Void) {
    DispatchQueue.global(qos: .background).async {
        callback()
    }
}

func dispatch_mainthread(_ callback: @escaping ()->Void) {
    DispatchQueue.main.async {
        callback()
    }
}
