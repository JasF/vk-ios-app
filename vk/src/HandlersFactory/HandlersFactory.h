//
//  HandlersFactory.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

@protocol WallServiceHandlerProtocol;

@protocol HandlersFactory <NSObject>
- (id<WallServiceHandlerProtocol>)wallServiceHandler;
@end
