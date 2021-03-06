//
//  ServicesAssembly.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ServicesAssembly.h"
#import "WallServiceImpl.h"
#import "ChatListServiceImpl.h"
#import "DialogServiceImpl.h"
#import "HandlersFactoryImpl.h"
#import "FriendsServiceImpl.h"
#import "WallPostServiceImpl.h"
#import "PhotoAlbumsServiceImpl.h"
#import "GalleryServiceImpl.h"
#import "AnswersServiceImpl.h"
#import "GroupsServiceImpl.h"
#import "BookmarksServiceImpl.h"
#import "VideosServiceImpl.h"
#import "DocumentsServiceImpl.h"
#import "SettingsServiceImpl.h"
#import "DetailPhotoServiceImpl.h"
#import "DetailVideoServiceImpl.h"
#import "PostsServiceImpl.h"
#import "Oxy_Feed-Swift.h"

@implementation ServicesAssembly

- (id<HandlersFactory>)handlersFactory {
    return [TyphoonDefinition withClass:[HandlersFactoryImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithPythonBridge:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:self.coreComponents.pythonBridge];
                 }];
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (id<WallService>)wallService {
    return [TyphoonDefinition withClass:[WallServiceImpl class] configuration:^(TyphoonDefinition *definition)
            {
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (id<ChatListService>)chatListService {
    return [TyphoonDefinition withClass:[ChatListServiceImpl class] configuration:^(TyphoonDefinition *definition)
            {
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (id<DialogService>)dialogService {
    return [TyphoonDefinition withClass:[DialogServiceImpl class] configuration:^(TyphoonDefinition *definition)
            {
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (id<FriendsService>)friendsService {
    return [TyphoonDefinition withClass:[FriendsServiceImpl class]];
}

- (id<WallPostService>)wallPostService {
    return [TyphoonDefinition withClass:[WallPostServiceImpl class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithWallService:) parameters:^(TyphoonMethod *initializer)
         {
             [initializer injectParameterWith:self.wallService];
         }];
        [definition injectProperty:@selector(commentsService) with:[self commentsService]];
    }];
}

- (id<PhotoAlbumsService>)photoAlbumsService {
    return [TyphoonDefinition withClass:[PhotoAlbumsServiceImpl class]];
}

- (id<GalleryService>)galleryService {
    return [TyphoonDefinition withClass:[GalleryServiceImpl class]];
}

- (id<DetailPhotoService>)detailPhotoService {
    return [TyphoonDefinition withClass:[DetailPhotoServiceImpl class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithGalleryService:) parameters:^(TyphoonMethod *initializer)
         {
             [initializer injectParameterWith:self.galleryService];
             [definition injectProperty:@selector(commentsService) with:[self commentsService]];
         }];
    }];
}

- (id<DetailVideoService>)detailVideoService {
    return [TyphoonDefinition withClass:[DetailVideoServiceImpl class] configuration:^(TyphoonDefinition *definition) {
        [definition injectProperty:@selector(commentsService) with:[self commentsService]];
    }];
}

- (id<AnswersService>)answersService {
    return [TyphoonDefinition withClass:[AnswersServiceImpl class]];
}

- (id<GroupsService>)groupsService {
    return [TyphoonDefinition withClass:[GroupsServiceImpl class]];
}

- (id<BookmarksService>)bookmarksService {
    return [TyphoonDefinition withClass:[BookmarksServiceImpl class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithWallService:) parameters:^(TyphoonMethod *initializer)
         {
             [initializer injectParameterWith:self.wallService];
         }];
    }];
}

- (id<VideosService>)videosService {
    return [TyphoonDefinition withClass:[VideosServiceImpl class]];
}

- (id<DocumentsService>)documentsService {
    return [TyphoonDefinition withClass:[DocumentsServiceImpl class]];
}

- (id<SettingsService>)settingsService {
    return [TyphoonDefinition withClass:[SettingsServiceImpl class]];
}

- (id<PostsService>)postsService {
    return [TyphoonDefinition withClass:[PostsServiceImpl class] configuration:^(TyphoonDefinition *definition) {
        [definition injectProperty:@selector(commentsService) with:[self commentsService]];
    }];
}

- (id<CommentsService>)commentsService {
    return [TyphoonDefinition withClass:[CommentsServiceImpl class]];
}

- (id<BlackListService>)blackListService {
    return [TyphoonDefinition withClass:[BlackListServiceImpl class]];
}

@end
