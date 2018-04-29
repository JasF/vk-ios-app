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
- (void)tappedOnPost:(WallPost *)post;
- (void)friendsTapped;
- (void)commonTapped;
- (void)subscribtionsTapped;
- (void)followersTapped;
- (void)photosTapped;
- (void)videosTapped;
- (void)groupsTapped;
- (void)messageButtonTapped;
- (void)friendButtonTapped;

@property CountUpdatedBlock friendsCountDidUpdated;
@property CountUpdatedBlock photosCountDidUpdated;
@property CountUpdatedBlock groupsCountDidUpdated;
@property CountUpdatedBlock videosCountDidUpdated;
@property CountUpdatedBlock interestPagesCountDidUpdated;

@end
