//
//  WallViewModelImpl.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "WallViewModel.h"
#import "HandlersFactory.h"
#import "WallService.h"

@protocol PyWallViewModel <NSObject>
- (NSDictionary *)getWall:(NSNumber *)offset;
- (void)menuTapped;
- (NSDictionary *)getUserInfo;
- (void)tappedOnPostWithId:(NSNumber *)identifier;
@end

@interface WallViewModelImpl : NSObject <WallViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                            wallService:(id<WallService>)wallService
                                 userId:(NSNumber *)userId;
@end
