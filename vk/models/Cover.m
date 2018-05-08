//
//  Cover.m
//  vk
//
//  Created by Jasf on 08.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Cover.h"

@implementation Cover

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"width", @"height", @"url"]];
    }];
}
        
@end
