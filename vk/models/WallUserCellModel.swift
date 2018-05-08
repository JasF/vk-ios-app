//
//  File.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objc protocol WallUserCellModelDelegate {
    func modelDidUpdated()
}

@objc enum WallUserCellModelType: Int {
    case image
    case message
    case actions
    case avatarNameDate
    case video
}
@objcMembers class WallUserCellModel : NSObject {
    var type:WallUserCellModelType
    var _user: User? = nil
    var user: User? {
        set {
            _user = newValue
            if let delegate = self.delegate {
                delegate.modelDidUpdated()
            }
        }
        get {
            return _user
        }
    }
    var date: Int = 0
    weak var delegate : WallUserCellModelDelegate? = nil
    init(_ type:WallUserCellModelType, user: User?) {
        self.type = type
        super.init()
        self.user = user
    }
    init(_ type:WallUserCellModelType, user: User?, date: Int) {
        self.type = type
        self.date = date
        super.init()
        self.user = user
    }
}
