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


- (id<FriendsViewModel>)friendsViewModel {
    return [TyphoonDefinition withClass:[FriendsViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:friendsService:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.servicesAssembly.friendsService];
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

@end
