//
//  PostsViewModel.h
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PostsViewModel <NSObject>
- (void)likeActionWithItem:(id)item completion:(void(^)(NSInteger likesCount, BOOL liked, BOOL error))completion;
- (void)repostActionWithItem:(id)item;
@end
