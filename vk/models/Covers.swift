//
//  Covers.swift
//  vk
//
//  Created by Jasf on 08.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation

@objcMembers class Covers : NSObject, EKMappingProtocol {
    var enabled: Bool = false
    var covers: NSArray? = nil
    override init() {
        super.init()
    }
    static func objectMapping() -> EKObjectMapping {
        return EKObjectMapping(for: self, with:{mapping in
            mapping.mapProperties(from: ["enabled"])
            mapping.mapKeyPath("images", toProperty: "covers", withValueBlock: { (_, value) -> Any? in
                if value == nil {
                    return nil
                }
                let covers = EKMapper.arrayOfObjects(fromExternalRepresentation: value as! [Any], with: Cover.objectMapping())
                return covers
            })
        });
    }
}
