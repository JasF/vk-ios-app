//
//  ScreensAssembly.h
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TyphoonAssembly.h"
#import "ScreensManager.h"
#import "ServicesAssembly.h"

@class VKCoreComponents;
@class VKThemeAssembly;
@class VKApplicationAssembly;
@class NodesAssembly;
@class ViewModelsAssembly;

@interface ScreensAssembly : TyphoonAssembly
@property (nonatomic, strong, readonly) VKCoreComponents *coreComponents;
@property (nonatomic, strong, readonly) VKThemeAssembly *themeProvider;
@property (nonatomic, strong, readonly) NodesAssembly *nodesAssembly;
@property (nonatomic, strong, readonly) VKApplicationAssembly *applicationAssembly;
@property (readonly) ServicesAssembly *servicesAssembly;
@property (readonly) ViewModelsAssembly *viewModelsAssembly;
- (id<ScreensManager>)screensManager;
- (UIViewController *)createViewController;
- (UIViewController *)createMainViewController;
- (UIViewController *)wallViewController:(NSNumber *)userId;
- (UIViewController *)wallPostViewControllerWithOwnerId:(NSNumber *)ownerId postId:(NSNumber *)postId;
- (UIViewController *)chatListViewController;
- (UIViewController *)friendsViewController;
- (UIViewController *)dialogViewController:(NSNumber *)userId;
- (UIViewController *)photoAlbumsViewController:(NSNumber *)ownerId;
- (UIViewController *)galleryViewController:(NSNumber *)ownerId albumId:(NSNumber *)albumId;
- (UIViewController *)imagesViewerViewController:(NSNumber *)ownerId albumId:(NSNumber *)albumId photoId:(NSNumber *)photoId;
- (UIViewController *)detailPhotoViewController:(NSNumber *)ownerId albumId:(NSNumber *)albumId photoId:(NSNumber *)photoId;
- (UIViewController *)newsViewController;
- (UIViewController *)answersViewController;
- (UIViewController *)groupsViewController:(NSNumber *)userId;
- (UIViewController *)bookmarksViewController;
- (UIViewController *)videosViewController:(NSNumber *)ownerId;
- (UIViewController *)documentsViewController:(NSNumber *)ownerId;
- (UIViewController *)settingsViewController;
- (UIWindow *)window;
- (UINavigationController *)rootNavigationController;
@end
