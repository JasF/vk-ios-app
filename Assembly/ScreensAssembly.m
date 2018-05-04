//
//  ScreensAssembly.m
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import "ScreensAssembly.h"
#import "AuthorizationViewController.h"
#import "VKCoreComponents.h"
#import "VKThemeAssembly.h"
#import "ScreensManagerImpl.h"
#import "WallViewController.h"
#import "ChatListViewController.h"
#import "BaseNavigationController.h"
#import "NodesAssembly.h"
#import "ServicesAssembly.h"
#import "ViewModelsAssembly.h"
#import "FriendsViewController.h"
#import "WallPostViewController.h"
#import "VKApplicationAssembly.h"
#import "PhotoAlbumsViewController.h"
#import "GalleryViewController.h"
#import "ImagesViewerViewController.h"
#import "NewsViewController.h"
#import "AnswersViewController.h"
#import "GroupsViewController.h"
#import "BookmarksViewController.h"
#import "VideosViewController.h"
#import "DocumentsViewController.h"
#import "SettingsViewController.h"
#import "DetailPhotoViewController.h"
#import "DetailVideoViewController.h"
#import "TextFieldDialogImpl.h"
#import "DialogsManagerImpl.h"
#import "RowsDialogImpl.h"
#import "CreatePostViewController.h"
#import "vk-Swift.h"

@implementation ScreensAssembly

#pragma mark - Public Methods

- (id<ScreensManager>)screensManager {
    return [TyphoonDefinition withClass:[ScreensManagerImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithVKSdkManager:pythonBridge:screensAssembly:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:[self.coreComponents vkManager]];
                     [initializer injectParameterWith:[self.coreComponents pythonBridge]];
                     [initializer injectParameterWith:self];
                 }];
                [definition injectProperty:@selector(window) with:[self window]];
                [definition injectProperty:@selector(dialogsManager) with:[self dialogsManager]];
                [definition injectProperty:@selector(mainViewController) with:[self createMainViewController]];
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (UIWindow *)window {
    return [TyphoonDefinition withClass:[UIWindow class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithFrame:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:[NSValue valueWithCGRect:[[UIScreen mainScreen] bounds]]];
                 }];
                [definition injectProperty:@selector(rootViewController) with:[self rootNavigationController]];
            }];
}

- (UINavigationController *)rootNavigationController {
    return [TyphoonDefinition withClass:[UINavigationController class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(init)];
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (UIViewController *)authorizationViewController
{
    return [TyphoonDefinition withClass:[AuthorizationViewController class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithViewModel:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:[self.viewModelsAssembly authorizationViewModel]];
                }];
            }];
}

- (UIViewController *)createMainViewController {
    return [TyphoonDefinition withFactory:[self mainStoryboard]
                                 selector:@selector(instantiateViewControllerWithIdentifier:)
                               parameters:^(TyphoonMethod *factoryMethod) {
                                   [factoryMethod injectParameterWith:@"MainViewController"];
                               }
                            configuration:^(TyphoonFactoryDefinition *definition) {
                                [definition injectProperty:@selector(rootViewController) with:[self mainNavigationController]];
                               }];
}

- (UIViewController *)wallViewController:(NSNumber *)userId {
    return [TyphoonDefinition withClass:[WallViewController class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:[self.viewModelsAssembly wallScreenViewModel:userId]];
                    [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
                }];
                [definition injectProperty:@selector(postsViewModel) with:[self.viewModelsAssembly postsViewModel]];
            }];
}

- (UIViewController *)wallPostViewControllerWithOwnerId:(NSNumber *)ownerId postId:(NSNumber *)postId {
    return [TyphoonDefinition withClass:[WallPostViewController class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:[self.viewModelsAssembly wallPostViewModelWithOwnerId:ownerId postId:postId]];
                    [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
                }];
                [definition injectProperty:@selector(postsViewModel) with:[self.viewModelsAssembly postsViewModel]];
            }];
}

- (DialogViewControllerAllocator *)dialogViewController:(NSNumber *)userId {
    return [TyphoonDefinition withClass:[DialogViewControllerAllocator class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:[self.viewModelsAssembly dialogScreenViewModel:userId]];
                    [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
                }];
            }];
}

- (UIViewController *)chatListViewController {
    return [TyphoonDefinition withClass:[ChatListViewController class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.viewModelsAssembly.chatListScreenViewModel];
                    [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
                }];
            }];
}

- (UIViewController *)friendsViewController:(NSNumber *)userId usersListType:(NSNumber *)usersListType {
    return [TyphoonDefinition withClass:[FriendsViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly friendsViewModel:userId usersListType:usersListType]];
            [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
        }];
    }];
}

- (UIViewController *)photoAlbumsViewController:(NSNumber *)ownerId {
    return [TyphoonDefinition withClass:[PhotoAlbumsViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly photoAlbumsViewModel:ownerId]];
            [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
        }];
    }];
}

- (UIViewController *)galleryViewController:(NSNumber *)ownerId albumId:(NSNumber *)albumId {
    return [TyphoonDefinition withClass:[GalleryViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly galleryViewModel:ownerId albumId:albumId]];
            [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
        }];
    }];
}

- (UIViewController *)imagesViewerViewController:(NSNumber *)ownerId postId:(NSNumber *)postId photoIndex:(NSNumber *)photoIndex {
    return [TyphoonDefinition withClass:[ImagesViewerViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithViewModel:photoBrowserViewModel:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly imagesViewerViewModel:ownerId postId:postId photoIndex:photoIndex]];
            [initializer injectParameterWith:[self.viewModelsAssembly photoBrowserViewModel]];
        }];
    }];
}

- (UIViewController *)imagesViewerViewController:(NSNumber *)ownerId albumId:(NSNumber *)albumId photoId:(NSNumber *)photoId {
    return [TyphoonDefinition withClass:[ImagesViewerViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithViewModel:photoBrowserViewModel:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly imagesViewerViewModel:ownerId albumId:albumId photoId:photoId]];
            [initializer injectParameterWith:[self.viewModelsAssembly photoBrowserViewModel]];
        }];
    }];
}

- (UIViewController *)detailPhotoViewController:(NSNumber *)ownerId albumId:(NSNumber *)albumId photoId:(NSNumber *)photoId {
    return [TyphoonDefinition withClass:[DetailPhotoViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly detailPhotoViewModel:ownerId albumId:albumId photoId:photoId]];
            [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
        }];
        [definition injectProperty:@selector(postsViewModel) with:[self.viewModelsAssembly postsViewModel]];
    }];
}

- (UIViewController *)newsViewController {
    return [TyphoonDefinition withClass:[NewsViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly newsViewModel]];
            [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
        }];
        [definition injectProperty:@selector(postsViewModel) with:[self.viewModelsAssembly postsViewModel]];
    }];
}

- (UIViewController *)answersViewController {
    return [TyphoonDefinition withClass:[AnswersViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly answersViewModel]];
            [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
        }];
    }];
}

- (UIViewController *)groupsViewController:(NSNumber *)userId {
    return [TyphoonDefinition withClass:[GroupsViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly groupsViewModel:userId]];
            [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
        }];
    }];
}

- (UIViewController *)bookmarksViewController {
    return [TyphoonDefinition withClass:[BookmarksViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly bookmarksViewModel]];
            [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
        }];
        [definition injectProperty:@selector(postsViewModel) with:[self.viewModelsAssembly postsViewModel]];
    }];
}

- (UIViewController *)videosViewController:(NSNumber *)ownerId {
    return [TyphoonDefinition withClass:[VideosViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly videosViewModel:ownerId]];
            [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
        }];
        [definition injectProperty:@selector(postsViewModel) with:[self.viewModelsAssembly postsViewModel]];
    }];
}

- (UIViewController *)documentsViewController:(NSNumber *)ownerId {
    return [TyphoonDefinition withClass:[DocumentsViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly documentsViewModel:ownerId]];
            [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
        }];
    }];
}

- (UIViewController *)settingsViewController {
    return [TyphoonDefinition withClass:[SettingsViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly settingsViewModel]];
            [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
        }];
    }];
}

- (UIViewController *)detailVideoViewController:(NSNumber *)ownerId videoId:(NSNumber *)videoId {
    return [TyphoonDefinition withClass:[DetailVideoViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithViewModel:nodeFactory:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly detailVideoViewModel:ownerId videoId:videoId]];
            [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
        }];
        [definition injectProperty:@selector(postsViewModel) with:[self.viewModelsAssembly postsViewModel]];
    }];
}

- (UIViewController *)videoPlayerViewController:(Video *)video {
    return [TyphoonDefinition withClass:[VideoPlayerViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(init:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly videoPlayerViewModel:video]];
        }];
    }];
}

- (UIViewController *)createPostViewController:(NSNumber *)ownerId {
    return [TyphoonDefinition withClass:[CreatePostViewController class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(init:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.viewModelsAssembly createPostViewModel:ownerId]];
        }];
    }];
}

- (id<TextFieldDialog>)textFieldDialog {
    return [TyphoonDefinition withClass:[TextFieldDialogImpl class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithScreensManager:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self screensManager]];
        }];
    }];
}

- (id<RowsDialog>)rowsDialog {
    return [TyphoonDefinition withClass:[RowsDialogImpl class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithScreensManager:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self screensManager]];
        }];
    }];
}

- (id<DialogsManager>)dialogsManager {
    return [TyphoonDefinition withClass:[DialogsManagerImpl class] configuration:^(TyphoonDefinition *definition) {
        [definition useInitializer:@selector(initWithHandlersFactory:textFieldDialog:rowsDialog:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:[self.servicesAssembly handlersFactory]];
            [initializer injectParameterWith:[self textFieldDialog]];
            [initializer injectParameterWith:[self rowsDialog]];
        }];
        definition.scope = TyphoonScopeSingleton;
    }];
}

- (BaseNavigationController *)mainNavigationController {
    return [TyphoonDefinition withFactory:[self mainStoryboard]
                                 selector:@selector(instantiateViewControllerWithIdentifier:)
                               parameters:^(TyphoonMethod *factoryMethod) {
                                   [factoryMethod injectParameterWith:@"NavigationController"];
                               }
                            configuration:^(TyphoonFactoryDefinition *definition) {
                                [definition injectProperty:@selector(viewControllers) with:@[[self mainChildViewController]]];
                            }];
}

- (BaseNavigationController *)mainChildViewController {
    return [TyphoonDefinition withFactory:[self mainStoryboard]
                                 selector:@selector(instantiateViewControllerWithIdentifier:)
                               parameters:^(TyphoonMethod *factoryMethod) {
                                   [factoryMethod injectParameterWith:@"ViewController"];
                               }];
}

#pragma mark - Private Methods
- (UIStoryboard *)mainStoryboard {
    return [TyphoonDefinition withClass:[TyphoonStoryboard class] configuration:^(TyphoonDefinition* definition) {
                [definition useInitializer:@selector(storyboardWithName:factory:bundle:) parameters:^(TyphoonMethod *initializer) {
                     [initializer injectParameterWith:@"Main"];
                     [initializer injectParameterWith:self];
                     [initializer injectParameterWith:[NSBundle mainBundle]];
                }];
                 definition.scope = TyphoonScopeSingleton; //Let's make this a singleton
            }];
}

- (UIStoryboard *)storyboardWithName:(NSString *)storyboardName {
    return [TyphoonDefinition withClass:[TyphoonStoryboard class] configuration:^(TyphoonDefinition* definition) {
        [definition useInitializer:@selector(storyboardWithName:factory:bundle:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:storyboardName];
            [initializer injectParameterWith:self];
            [initializer injectParameterWith:[NSBundle mainBundle]];
        }];
    }];
}

@end
