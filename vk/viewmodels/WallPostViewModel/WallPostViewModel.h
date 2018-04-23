//
//  WallPostViewModel.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallPost.h"

@protocol WallPostViewModel <NSObject>
- (void)getWallPostWithCommentsOffset:(NSInteger)offset completion:(void(^)(WallPost *post, NSArray *comments))completion;
@end
