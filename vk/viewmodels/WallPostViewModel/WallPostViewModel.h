//
//  WallPostViewModel.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#ifndef WallPostViewModel_h
#define WallPostViewModel_h


#import "WallPost.h"

@protocol WallPostViewModel <NSObject>
- (WallPost *)getWallPost;
@end

#endif /* WallPostViewModel_h */
