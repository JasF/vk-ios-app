//
//  WallServiceImpl.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallService.h"
#import "HandlersFactory.h"

@protocol WallServiceHandlerProtocol <NSObject>
- (NSDictionary *)getWall:(NSNumber *)offset;
@end

@interface WallServiceImpl : NSObject <WallService>
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory;
@end
