//
//  PostType.m
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostType.h"

@implementation PostType

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapKeyPath:@"post_type" toProperty:@"postTypeString"];
    }];
}

- (void)setPostTypeString:(NSString *)postTypeString {
    NSDictionary *dictionary = @{@"post":@(PostTypePost)};
    _type = [dictionary[postTypeString] integerValue];
}

@end
