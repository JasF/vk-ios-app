//
//  WallPostViewModelImpl.m
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallPostViewModelImpl.h"
#import "HandlersFactory.h"
#import "WallPostService.h"

@interface WallPostViewModelImpl ()
@property id<WallPostService> wallPostService;
@property id<PyWallPostViewModel> handler;
@end

@implementation WallPostViewModelImpl

- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                        wallPostService:(id<WallPostService>)wallPostService
                                ownerId:(NSNumber *)ownerId
                                 postId:(NSNumber *)postId {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(wallPostService);
    NSCParameterAssert(ownerId);
    NSCParameterAssert(postId);
    if (self) {
        _handler = [handlersFactory wallPostViewModelHandlerWithDelegate:self parameters:@{@"ownerId": ownerId, @"postId": postId}];
        _wallPostService = wallPostService;
    }
    return self;
}

- (void)getWallPostWithCommentsOffset:(NSInteger)offset
                            postBlock:(void(^)(WallPost *post))postBlock
                           completion:(void(^)(NSArray *comments))completion {
    if (postBlock) {
        dispatch_python(^{
            NSDictionary *response = [self.handler getCachedPost];
            WallPost *post = [self.wallPostService parseOne:response[@"postData"]];
            dispatch_async(dispatch_get_main_queue(), ^{
                postBlock(post);
            });
        });
    }
    else {dispatch_python(^{
        NSDictionary *response = [self.handler getPostData:@(offset)];
        NSArray *comments = [self.wallPostService parseComments:response[@"comments"]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(comments);
            }
        });
    });
    }
}

@end
