//
//  MWPhotoBrowserViewModel.swift
//  vk
//
//  Created by Jasf on 04.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objc protocol PyMWPhotoBrowserViewModel {
    func numberOfComments(_ photoId: NSNumber, ownerId: NSNumber) -> NSNumber
}

@objcMembers class MWPhotoBrowserViewModelImpl : NSObject, MWPhotoBrowserViewModel {
    var handler : PyMWPhotoBrowserViewModel!
    init(_ handlersFactory: HandlersFactory) {
        handler = handlersFactory.photoBrowserViewModelHandler()
        super.init()
    }
    func getNumberOfComments(with photo: MWPhoto!, completion: ((Int) -> Void)!) {
        guard let model = photo.model as! Photo? else {
            completion(-1)
            return
        }
        dispatch_python() {
            let numberOfComments = self.handler.numberOfComments(model.id as NSNumber, ownerId: model.owner_id as NSNumber)
            if !numberOfComments.isKind(of: NSNumber.self) {
                completion(0)
                return
            }
            DispatchQueue.main.async {
                completion(numberOfComments as! Int)
            }
        }
    }
}