//
//  ViewModelsAssembly.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "TyphoonAssembly.h"
#import "VKApplicationAssembly.h"
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
#import "NewsViewModel.h"
#import "AnswersViewModel.h"
#import "GroupsViewModel.h"
#import "BookmarksViewModel.h"
#import "VideosViewModel.h"
#import "DocumentsViewModel.h"
#import "SettingsViewModel.h"
#import "DetailPhotoViewModel.h"
#import "AuthorizationViewModel.h"
#import "DetailVideoViewModel.h"
#import "PostsViewModel.h"

@protocol VideoPlayerViewModel;

@interface ViewModelsAssembly : TyphoonAssembly
@property (readonly) VKCoreComponents *coreComponents;
@property (readonly) ServicesAssembly *servicesAssembly;
@property (readonly) ScreensAssembly *screensAssembly;
@property (readonly) VKApplicationAssembly *applicationAssembly;
- (id<DialogScreenViewModel>)dialogScreenViewModel:(NSNumber *)userId;
- (id<ChatListViewModel>)chatListScreenViewModel;
- (id<WallViewModel>)wallScreenViewModel:(NSNumber *)userId;
- (id<MenuViewModel>)menuScreenViewModel;
- (id<FriendsViewModel>)friendsViewModel:(NSNumber *)userId usersListType:(NSNumber *)usersListType;
- (id<WallPostViewModel>)wallPostViewModelWithOwnerId:(NSNumber *)ownerId postId:(NSNumber *)postId;
- (id<PhotoAlbumsViewModel>)photoAlbumsViewModel:(NSNumber *)ownerId;
- (id<GalleryViewModel>)galleryViewModel:(NSNumber *)ownerId albumId:(NSNumber *)albumId;
- (id<ImagesViewerViewModel>)imagesViewerViewModel:(NSNumber *)ownerId albumId:(NSNumber *)albumId photoId:(NSNumber *)photoId;
- (id<DetailPhotoViewModel>)detailPhotoViewModel:(NSNumber *)ownerId albumId:(NSNumber *)albumId photoId:(NSNumber *)photoId;
- (id<NewsViewModel>)newsViewModel;
- (id<AnswersViewModel>)answersViewModel;
- (id<GroupsViewModel>)groupsViewModel:(NSNumber *)userId;
- (id<BookmarksViewModel>)bookmarksViewModel;
- (id<VideosViewModel>)videosViewModel:(NSNumber *)ownerId;
- (id<DocumentsViewModel>)documentsViewModel:(NSNumber *)ownerId;
- (id<SettingsViewModel>)settingsViewModel;
- (id<AuthorizationViewModel>)authorizationViewModel;
- (id<DetailVideoViewModel>)detailVideoViewModel:(NSNumber *)ownerId videoId:(NSNumber *)videoId;
- (id<PostsViewModel>)postsViewModel;
- (id<VideoPlayerViewModel>)videoPlayerViewModel:(Video *)video;
@end
