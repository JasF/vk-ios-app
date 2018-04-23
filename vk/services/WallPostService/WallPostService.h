//
//  WallPostService.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallPost.h"

@protocol WallPostService <NSObject>
- (WallPost *)parseOne:(NSDictionary *)post;
- (NSArray *)parseComments:(NSDictionary *)comments;
@end
