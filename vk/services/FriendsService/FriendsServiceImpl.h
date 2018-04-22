//
//  FriendsServiceImpl.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "FriendsService.h"

@interface FriendsServiceImpl : NSObject<FriendsService>
- (NSArray<User *> *)parse:(NSDictionary *)friendsData;
@end
