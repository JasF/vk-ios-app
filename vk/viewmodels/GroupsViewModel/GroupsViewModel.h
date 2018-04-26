//
//  GroupsViewModel.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

@protocol GroupsViewModel <NSObject>
- (void)getGroups:(NSInteger)offset completion:(void(^)(NSArray *groups))completion;
- (void)menuTapped;
- (void)tappedOnGroup:(User *)user;
@end
