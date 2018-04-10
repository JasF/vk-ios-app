//
//  Likes.m
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "Likes.h"

@implementation Likes

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"count"]];
        [mapping mapKeyPath:@"can_like" toProperty:@"canLike"];
        [mapping mapKeyPath:@"can_publish" toProperty:@"canPublish"];
        [mapping mapKeyPath:@"user_likes" toProperty:@"userLikes"];
    }];
}

@end
