//
//  WallViewModel.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "User.h"
#import "WallPost.h"

typedef void (^CountUpdatedBlock)(NSNumber *);
@protocol WallViewModel <NSObject>
@property User *currentUser;
- (void)getWallPostsWithOffset:(NSInteger)offset
                    completion:(void(^)(NSArray *posts))completion;
- (void)menuTapped;
- (void)friendsTapped;
- (void)commonTapped;
- (void)subscribtionsTapped;
- (void)followersTapped;
- (void)photosTapped;
- (void)videosTapped;
- (void)groupsTapped;
- (void)messageButtonTapped;
- (void)friendButtonTapped:(void(^)(NSInteger resultCode))callback;
- (void)addPostTapped;
- (void)getLatestPostsWithCompletion:(void(^)(NSArray *objects))callback;
- (void)getUserInfo:(void(^)(User *user))completion;
@end
