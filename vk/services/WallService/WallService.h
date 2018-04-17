//
//  WallService.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import "WallPost.h"

@protocol WallService <NSObject>
- (NSArray<WallPost *> *)parse:(NSDictionary *)data;
@end
