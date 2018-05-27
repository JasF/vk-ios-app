//
//  FriendsViewModel.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#ifndef FriendsViewModel_h
#define FriendsViewModel_h

#import <Foundation/Foundation.h>
#import "User.h"

@protocol FriendsViewModel <NSObject>
- (void)menuTapped;
- (void)getFriendsWithOffset:(NSInteger)offset
                  completion:(void(^)(NSArray<User *> *users, NSError *error))completion;
- (void)tappedOnUserWithId:(NSInteger)userId;
@end


#endif /* FriendsViewModel_h */
