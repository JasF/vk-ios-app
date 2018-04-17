//
//  WallScreenViewModelImpl.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "WallScreenViewModel.h"
#import "HandlersFactory.h"
#import "WallService.h"

@protocol PyWallScreenViewModel <NSObject>
- (NSDictionary *)getWall:(NSNumber *)offset;
- (void)menuTapped;
@end

@interface WallScreenViewModelImpl : NSObject <WallScreenViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                            wallService:(id<WallService>)wallService;
@end
