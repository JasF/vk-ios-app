//
//  LastSeen.swift
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import EasyMapping

@objcMembers class LastSeen : EKMappingProtocol {
    static func objectMapping() -> EKObjectMapping {
        return EKObjectMapping(for: self, with:{mapping in
            
        });
    }
}
