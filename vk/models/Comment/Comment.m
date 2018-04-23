//
//  Comment.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Comment.h"

@implementation Comment
+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"id", @"from_id", @"date", @"text", @"reply_to_user", @"reply_to_comment"]];
    }];
}
@end
