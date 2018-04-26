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
#import "ChatListService.h"
#import "DialogService.h"
#import "FriendsService.h"
#import "WallPostService.h"
#import "PhotoAlbumsService.h"
#import "GalleryService.h"
#import "AnswersService.h"
#import "GroupsService.h"
#import "BookmarksService.h"
#import "VideosService.h"
#import "DocumentsService.h"
#import "SettingsService.h"
#import "GalleryService.h"
#import "DetailPhotoService.h"
#import "DetailVideoService.h"

@interface ServicesAssembly : TyphoonAssembly
@property (readonly) VKCoreComponents *coreComponents;
- (id<HandlersFactory>)handlersFactory;
- (id<WallService>)wallService;
- (id<ChatListService>)chatListService;
- (id<DialogService>)dialogService;
- (id<FriendsService>)friendsService;
- (id<WallPostService>)wallPostService;
- (id<PhotoAlbumsService>)photoAlbumsService;
- (id<GalleryService>)galleryService;
- (id<AnswersService>)answersService;
- (id<GroupsService>)groupsService;
- (id<BookmarksService>)bookmarksService;
- (id<VideosService>)videosService;
- (id<DocumentsService>)documentsService;
- (id<SettingsService>)settingsService;
- (id<GalleryService>)galleryService;
- (id<DetailPhotoService>)detailPhotoService;
- (id<DetailVideoService>)detailVideoService;
@end
