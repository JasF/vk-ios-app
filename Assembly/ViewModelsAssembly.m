//
//  ViewModelsAssembly.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ViewModelsAssembly.h"
#import "DialogScreenViewModelImpl.h"
#import "ChatListViewModelImpl.h"
#import "FriendsViewModelImpl.h"
#import "WallViewModelImpl.h"
#import "WallPostViewModelImpl.h"
#import "MenuViewModelImpl.h"
#import "PhotoAlbumsViewModelImpl.h"
#import "GalleryViewModelImpl.h"
#import "ImagesViewerViewModelImpl.h"
#import "NewsViewModelImpl.h"
#import "AnswersViewModelImpl.h"
#import "GroupsViewModelImpl.h"
#import "BookmarksViewModelImpl.h"
#import "VideosViewModelImpl.h"
#import "DocumentsViewModelImpl.h"
#import "SettingsViewModelImpl.h"
#import "DetailPhotoViewModelImpl.h"
#import "AuthorizationViewModelImpl.h"
#import "DetailVideoViewModelImpl.h"
#import "PostsViewModelImpl.h"
#import "vk-Swift.h"

@implementation ViewModelsAssembly

- (id<DialogScreenViewModel>)dialogScreenViewModel:(NSNumber *)userId {
    return [TyphoonDefinition withClass:[DialogScreenViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithDialogService:handlersFactory:userId:pythonBridge:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.dialogService];
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:userId];
                    [initializer injectParameterWith:self.coreComponents.pythonBridge];
                }];
            }];
}

- (id<ChatListViewModel>)chatListScreenViewModel {
    return [TyphoonDefinition withClass:[ChatListViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:chatListService:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.chatListService];
                }];
            }];
}

- (id<FriendsViewModel>)friendsViewModel:(NSNumber *)userId usersListType:(NSNumber *)usersListType {
    return [TyphoonDefinition withClass:[FriendsViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:friendsService:userId:usersListType:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.friendsService];
                    [initializer injectParameterWith:userId];
                    [initializer injectParameterWith:usersListType];
                }];
            }];
}

- (id<WallViewModel>)wallScreenViewModel:(NSNumber *)userId {
    return [TyphoonDefinition withClass:[WallViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:wallService:userId:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.wallService];
                    [initializer injectParameterWith:userId];
                }];
            }];
}

- (id<WallPostViewModel>)wallPostViewModelWithOwnerId:(NSNumber *)ownerId postId:(NSNumber *)postId {
    return [TyphoonDefinition withClass:[WallPostViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:wallPostService:ownerId:postId:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.wallPostService];
                    [initializer injectParameterWith:ownerId];
                    [initializer injectParameterWith:postId];
                }];
            }];
}

- (id<MenuViewModel>)menuScreenViewModel {
    return [TyphoonDefinition withClass:[MenuViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                }];
            }];
}

- (id<PhotoAlbumsViewModel>)photoAlbumsViewModel:(NSNumber *)ownerId {
    return [TyphoonDefinition withClass:[PhotoAlbumsViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:photoAlbumsService:ownerId:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.photoAlbumsService];
                    [initializer injectParameterWith:ownerId];
                }];
            }];
}

- (id<GalleryViewModel>)galleryViewModel:(NSNumber *)ownerId albumId:(NSNumber *)albumId {
    return [TyphoonDefinition withClass:[GalleryViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:galleryService:ownerId:albumId:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.galleryService];
                    [initializer injectParameterWith:ownerId];
                    [initializer injectParameterWith:albumId];
                }];
            }];
}


- (id<DetailPhotoViewModel>)imagesViewerViewModel:(NSNumber *)ownerId postId:(NSNumber *)postId photoIndex:(NSNumber *)photoIndex {
    return [TyphoonDefinition withClass:[ImagesViewerViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:galleryService:ownerId:postId:photoIndex:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.galleryService];
                    [initializer injectParameterWith:ownerId];
                    [initializer injectParameterWith:postId];
                    [initializer injectParameterWith:photoIndex];
                }];
            }];
}

- (id<ImagesViewerViewModel>)imagesViewerViewModel:(NSNumber *)ownerId albumId:(NSNumber *)albumId photoId:(NSNumber *)photoId {
    return [TyphoonDefinition withClass:[ImagesViewerViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:galleryService:ownerId:albumId:photoId:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.galleryService];
                    [initializer injectParameterWith:ownerId];
                    [initializer injectParameterWith:albumId];
                    [initializer injectParameterWith:photoId];
                }];
            }];
}

- (id<DetailPhotoViewModel>)detailPhotoViewModel:(NSNumber *)ownerId photoId:(NSNumber *)photoId {
    return [TyphoonDefinition withClass:[DetailPhotoViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:detailPhotoService:ownerId:photoId:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.detailPhotoService];
                    [initializer injectParameterWith:ownerId];
                    [initializer injectParameterWith:photoId];
                }];
            }];
}

- (id<NewsViewModel>)newsViewModel {
    return [TyphoonDefinition withClass:[NewsViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:wallService:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.wallService];
                }];
            }];
}

- (id<AnswersViewModel>)answersViewModel {
    return [TyphoonDefinition withClass:[AnswersViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:answersService:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.answersService];
                }];
            }];

}

- (id<GroupsViewModel>)groupsViewModel:(NSNumber *)userId {
    return [TyphoonDefinition withClass:[GroupsViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:groupsService:userId:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.groupsService];
                    [initializer injectParameterWith:userId];
                }];
            }];
}

- (id<BookmarksViewModel>)bookmarksViewModel {
    return [TyphoonDefinition withClass:[BookmarksViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:bookmarksService:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.bookmarksService];
                }];
            }];
}

- (id<VideosViewModel>)videosViewModel:(NSNumber *)ownerId {
    return [TyphoonDefinition withClass:[VideosViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:videosService:ownerId:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.videosService];
                    [initializer injectParameterWith:ownerId];
                }];
            }];
}

- (id<DocumentsViewModel>)documentsViewModel:(NSNumber *)ownerId {
    return [TyphoonDefinition withClass:[DocumentsViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:documentsService:ownerId:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.documentsService];
                    [initializer injectParameterWith:ownerId];
                }];
            }];
}

- (id<VideoPlayerViewModel>)videoPlayerViewModel:(Video *)video {
    return [TyphoonDefinition withClass:[VideoPlayerViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(init:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:video];
                }];
            }];
}

- (id<SettingsViewModel>)settingsViewModel {
    return [TyphoonDefinition withClass:[SettingsViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:settingsService:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.settingsService];
                }];
            }];
}

- (id<AuthorizationViewModel>)authorizationViewModel {
    return [TyphoonDefinition withClass:[AuthorizationViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:vkManager:notificationsManager:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.coreComponents.vkManager];
                    [initializer injectParameterWith:self.applicationAssembly.notificationsManager];
                }];
            }];
}

- (id<DetailVideoViewModel>)detailVideoViewModel:(NSNumber *)ownerId videoId:(NSNumber *)videoId {
    return [TyphoonDefinition withClass:[DetailVideoViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:detailVideoService:ownerId:videoId:screensManager:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.detailVideoService];
                    [initializer injectParameterWith:ownerId];
                    [initializer injectParameterWith:videoId];
                    [initializer injectParameterWith:self.screensAssembly.screensManager];
                }];
            }];
}

- (id<PostsViewModel>)postsViewModel {
    return [TyphoonDefinition withClass:[PostsViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:postsService:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.postsService];
                }];
            }];
}

- (id<CreatePostViewModel>)createPostViewModel:(NSNumber *)ownerId {
    return [TyphoonDefinition withClass:[CreatePostViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(init:ownerId:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:ownerId];
                }];
            }];
}

- (id<MWPhotoBrowserViewModel>)photoBrowserViewModel {
    return [TyphoonDefinition withClass:[MWPhotoBrowserViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(init:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                }];
            }];
}

@end
