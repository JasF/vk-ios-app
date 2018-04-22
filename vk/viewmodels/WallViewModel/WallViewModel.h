//
//  WallViewModel.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "User.h"
#import "WallPost.h"

@protocol WallViewModel <NSObject>
@property User *currentUser;
- (void)getWallPostsWithOffset:(NSInteger)offset
                    completion:(void(^)(NSArray *posts))completion;
- (void)menuTapped;
- (void)tappedOnPost:(WallPost *)post;
@end
