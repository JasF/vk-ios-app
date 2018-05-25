//
//  BlackListViewModel.swift
//  Oxy Feed
//
//  Created by Jasf on 25.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objc protocol BlackListViewModel {
    func getBanned(_ offset: Int, completion: @escaping (([Any]) -> Void))
}

@objc protocol PyBlackListViewModel {
    func getBanned(_ offset: NSNumber) -> Dictionary<String, Any>?
}

@objcMembers class BlackListViewModelImpl : NSObject, BlackListViewModel {
    var handler : PyBlackListViewModel!
    var service : BlackListService!
    init(_ handlersFactory: HandlersFactory, service: BlackListService) {
        handler = handlersFactory.blackListViewModelHandler()
        self.service = service
        super.init()
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
}
