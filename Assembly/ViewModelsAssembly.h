//
//  ViewModelsAssembly.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
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
#import "WallPostViewModel.h"
#import "PhotoAlbumsViewModel.h"
#import "GalleryViewModel.h"
#import "ImagesViewerViewModel.h"

@interface ViewModelsAssembly : TyphoonAssembly
@property (readonly) VKCoreComponents *coreComponents;
@property (readonly) ServicesAssembly *servicesAssembly;
@property (readonly) ScreensAssembly *screensAssembly;
- (id<DialogScreenViewModel>)dialogScreenViewModel:(NSNumber *)userId;
- (id<ChatListViewModel>)chatListScreenViewModel;
- (id<WallViewModel>)wallScreenViewModel:(NSNumber *)userId;
- (id<MenuViewModel>)menuScreenViewModel;
- (id<FriendsViewModel>)friendsViewModel;
- (id<WallPostViewModel>)wallPostViewModelWithOwnerId:(NSNumber *)ownerId postId:(NSNumber *)postId;
- (id<PhotoAlbumsViewModel>)photoAlbumsViewModel:(NSNumber *)ownerId;
- (id<GalleryViewModel>)galleryViewModel:(NSNumber *)ownerId albumId:(NSNumber *)albumId;
- (id<ImagesViewerViewModel>)imagesViewerViewModel:(NSNumber *)ownerId albumId:(NSNumber *)albumId photoId:(NSNumber *)photoId;
@end
