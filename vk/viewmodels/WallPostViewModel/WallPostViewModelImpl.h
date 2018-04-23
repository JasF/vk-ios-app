//
//  WallPostViewModelImpl.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WallPostViewModel.h"
#import "HandlersFactory.h"
#import "WallPostService.h"

@protocol PyWallPostViewModel <NSObject>
- (NSDictionary *)getPostData:(NSNumber *)offset;
@end

@interface WallPostViewModelImpl : NSObject <WallPostViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                        wallPostService:(id<WallPostService>)wallPostService
                                ownerId:(NSNumber *)ownerId
                                 postId:(NSNumber *)postId;
@end
