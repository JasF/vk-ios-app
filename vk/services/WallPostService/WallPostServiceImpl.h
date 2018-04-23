//
//  WallPostServiceImpl.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallPostService.h"
#import "WallService.h"

@interface WallPostServiceImpl : NSObject <WallPostService>
- (id)initWithWallService:(id<WallService>)wallService;
@end
