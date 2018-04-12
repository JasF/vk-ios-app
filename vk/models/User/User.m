//
//  User.m
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "User.h"

@implementation User

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"first_name", @"last_name", @"name", @"photo_50", @"photo_100", @"photo_200_orig", @"photo_200", @"photo_400_orig", @"photo_max", @"photo_max_orig"]];
        [mapping mapKeyPath:@"id" toProperty:@"identifier"];
    }];
}

- (NSString *)nameString {
    if (_name.length) {
        return _name;
    }
    else if (_first_name.length && _last_name.length) {
        return [NSString stringWithFormat:@"%@ %@", _first_name, _last_name];
    }
    else if (_first_name.length) {
        return _first_name;
    }
    return _last_name;
}
@end
