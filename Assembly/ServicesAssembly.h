//
//  ServicesAssembly.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "TyphoonAssembly.h"
#import "HandlersFactory.h"
#import "VKCoreComponents.h"
#import "WallService.h"
#import "DialogsService.h"

@interface ServicesAssembly : TyphoonAssembly
@property (readonly) VKCoreComponents *coreComponents;
- (id<HandlersFactory>)handlersFactory;
- (id<WallService>)wallService;
- (id<DialogsService>)dialogsService;
@end
