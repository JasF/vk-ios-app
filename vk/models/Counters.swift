//
//  Counters.swift
//  vk
//
//  Created by Jasf on 08.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import EasyMapping

@objcMembers class Counters : EKMappingProtocol {
    var photos : Int = 0
    var albums : Int = 0
    var topics : Int = 0
    var videos : Int = 0
    var audios : Int = 0
    static func objectMapping() -> EKObjectMapping {
        return EKObjectMapping(for: self, with:{mapping in
            mapping.mapProperties(from: ["photos, albums, topics, videos, audios"])
        });
    }
}
