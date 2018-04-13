//
//  ServicesAssembly.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "TyphoonAssembly.h"
#import "HandlersFactory.h"
#import "WallService.h"
#import "VKCoreComponents.h"

@interface ServicesAssembly : TyphoonAssembly
@property (readonly) VKCoreComponents *coreComponents;
- (id<HandlersFactory>)handlersFactory;
- (id<WallService>)wallService;
@end
