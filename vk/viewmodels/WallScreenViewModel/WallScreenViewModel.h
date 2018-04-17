//
//  WallScreenViewModel.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

@protocol WallScreenViewModel <NSObject>
- (void)getWallPostsWithOffset:(NSInteger)offset
                    completion:(void(^)(NSArray *posts))completion;
- (void)menuTapped;
@end
