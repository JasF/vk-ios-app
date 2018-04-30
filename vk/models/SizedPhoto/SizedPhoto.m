//
//  SizedPhoto.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "SizedPhoto.h"

@implementation SizedPhoto

+ (NSArray *)types {
    return @[@"s", @"m", @"x"];
}

+ (SizedPhoto *)getWithType:(NSString *)type array:(NSArray *)array {
    for (SizedPhoto *photo in array) {
        if ([photo.type isEqualToString:type]) {
            return photo;
        }
    }
    NSInteger index = [[self types] indexOfObject:type];
    if (index > 0) {
        return [self getWithType:[self types][index - 1] array:array];
    }
    return nil;
}

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"src", @"width", @"height", @"type"]];
    }];
}

@end
