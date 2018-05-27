//
//  BlackListViewModel.swift
//  Oxy Feed
//
//  Created by Jasf on 25.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objc protocol PyBlackListViewModelDelegate {
    func localize(_ string: String) -> String
}

@objc protocol BlackListViewModel {
    func getBanned(_ offset: Int, completion: @escaping (([Any]) -> Void))
    func unbanUser(_ user: User, completion: @escaping ((Bool) -> Void))
    func tappedWithUser(_ user: User)
}

@objc protocol PyBlackListViewModel {
    func getBanned(_ offset: NSNumber) -> Dictionary<String, Any>?
    func unbanUser(_ userId: NSNumber) -> NSNumber
    func tappedWithUserId(_ userId: NSNumber)
}

@objcMembers class BlackListViewModelImpl : NSObject, BlackListViewModel, PyBlackListViewModelDelegate {
    var handler : PyBlackListViewModel!
    var service : BlackListService!
    init(_ handlersFactory: HandlersFactory, service: BlackListService) {
        self.service = service
        super.init()
        handler = handlersFactory.blackListViewModelHandler(self)
    }
    
    func getBanned(_ offset: Int, completion: @escaping (([Any]) -> Void)) {
        dispatch_python { [weak self] in
            var objects:[Any] = []
            defer {
                dispatch_mainthread {
                    completion(objects)
                }
            }
            guard let response = self?.handler.getBanned(offset as NSNumber) else { return }
            if let array = self?.service.usersFromResponse(response) {
                objects = array
            }
        }
    }
    
    func unbanUser(_ user: User, completion: @escaping ((Bool) -> Void)) {
        dispatch_python { [weak self] in
            var result = false
            defer {
                dispatch_mainthread {
                    completion(result)
                }
            }
            if let boolResult = self?.handler.unbanUser(user.id as NSNumber) {
                result = boolResult.boolValue
            }
        }
    }
    
    func tappedWithUser(_ user: User) {
        dispatch_python { [weak self] in
            self?.handler.tappedWithUserId(user.id as NSNumber)
        }
    }
    
    func localize(_ string: String) -> String {
        return string.localized
    }
}
