//
//  FriendsService.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@protocol FriendsService <NSObject>
- (NSArray<User *> *)parse:(NSDictionary *)friendsData;
@end

