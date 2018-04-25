//
//  BookmarksServiceImpl.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BookmarksService.h"
#import "WallService.h"

@interface BookmarksServiceImpl : NSObject <BookmarksService>
- (id)initWithWallService:(id<WallService>)wallService;
@end
