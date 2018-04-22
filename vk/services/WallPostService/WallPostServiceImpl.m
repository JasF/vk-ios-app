//
//  WallPostServiceImpl.m
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "WallPostServiceImpl.h"

@implementation WallPostServiceImpl

- (WallPost *)parseOne:(NSDictionary *)postData {
    WallPost *post = [EKMapper objectFromExternalRepresentation:postData
                                                    withMapping:[WallPost objectMapping]];
    return post;
}

@end
