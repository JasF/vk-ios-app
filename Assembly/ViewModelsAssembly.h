//
//  ViewModelsAssembly.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "TyphoonAssembly.h"
#import "VKCoreComponents.h"
#import "ServicesAssembly.h"
#import "ScreensAssembly.h"
#import "DialogScreenViewModel.h"
#import "ChatListViewModel.h"
#import "WallViewModel.h"
#import "MenuViewModel.h"
#import "FriendsViewModel.h"

@interface ViewModelsAssembly : TyphoonAssembly
@property (readonly) VKCoreComponents *coreComponents;
@property (readonly) ServicesAssembly *servicesAssembly;
@property (readonly) ScreensAssembly *screensAssembly;
- (id<DialogScreenViewModel>)dialogScreenViewModel:(NSNumber *)userId;
- (id<ChatListViewModel>)chatListScreenViewModel;
- (id<WallViewModel>)wallScreenViewModel;
- (id<MenuViewModel>)menuScreenViewModel;
- (id<FriendsViewModel>)friendsViewModel;
@end
