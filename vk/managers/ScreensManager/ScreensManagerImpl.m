//
//  ScreensManagerImpl.m
//  vk
//
//  Created by Jasf on 09.04.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import "ScreensManagerImpl.h"
#import "MainViewController.h"
#import "ScreensAssembly.h"
#import "AuthorizationViewController.h"
#import "WallViewController.h"
#import "ChatListViewController.h"
#import "BaseNavigationController.h"
#import "vk-Swift.h"
#import "MenuViewController.h"
#import "ViewModelsAssembly.h"
#import "FriendsViewController.h"
#import "WallPostViewController.h"
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

@interface ScreensManagerImpl ()
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) id<VKSdkManager> vkSdkManager;
@property (strong, nonatomic) id<PythonBridge> pythonBridge;
@property (strong, nonatomic) ScreensAssembly *screensAssembly;
@property (strong, nonatomic) id<DialogsManager> dialogsManager;
@property (strong, nonatomic) UINavigationController *rootNavigationController;
@end

@implementation ScreensManagerImpl

#pragma mark - Initialization
- (id)initWithVKSdkManager:(id<VKSdkManager>)vkSdkManager
              pythonBridge:(id<PythonBridge>)pythonBridge
           screensAssembly:(ScreensAssembly *)screensAssembly {
    NSCParameterAssert(vkSdkManager);
    NSCParameterAssert(pythonBridge);
    NSCParameterAssert(screensAssembly);
    if (self = [super init]) {
        _vkSdkManager = vkSdkManager;
        _pythonBridge = pythonBridge;
        _screensAssembly = screensAssembly;
        [_pythonBridge setClassHandler:self name:@"ScreensManager"];
    }
    return self;
}

#pragma mark - overriden methods ScreensManager
- (void)createWindowIfNeeded {
    if (!self.window.isKeyWindow) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LaunchScreen" bundle:nil];
        self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
        [self.window makeKeyAndVisible];
    }
}

- (void)showAuthorizationViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.window.rootViewController = self.rootNavigationController;
        UIViewController *viewController = [self.screensAssembly authorizationViewController];
        self.rootNavigationController.viewControllers = @[viewController];
    });
}

- (void)showWallViewController {
    [self showWallViewController:@(0)];
}

- (void)showWallViewController:(NSNumber *)userId {
    [self showWallViewController:userId push:@(NO)];
}

- (void)showWallViewController:(NSNumber *)userId push:(NSNumber *)push {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        WallViewController *viewController =(WallViewController *)[_screensAssembly wallViewController:userId];
        viewController.pushed = push.boolValue;
        [self pushViewController:viewController clean:!push.boolValue];
    });
}

- (void)showWallPostViewControllerWithOwnerId:(NSNumber *)ownerId postId:(NSNumber *)postId {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        WallPostViewController *viewController =(WallPostViewController *)[_screensAssembly wallPostViewControllerWithOwnerId:ownerId postId:postId];
        [self pushViewController:viewController clean:NO];
    });
}

- (void)showChatListViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        if ([self canIgnorePushingViewController:[ChatListViewController class]]) {
            return;
        }
        ChatListViewController *viewController =(ChatListViewController *)[_screensAssembly chatListViewController];
        [self pushViewController:viewController];
    });
}

- (void)showFriendsViewController:(NSNumber *)userId usersListType:(NSNumber *)usersListType {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        if ([self canIgnorePushingViewController:[FriendsViewController class]]) {
            return;
        }
        FriendsViewController *viewController =(FriendsViewController *)[_screensAssembly friendsViewController:userId usersListType:usersListType];
        [self pushViewController:viewController];
    });
}

- (void)presentAddPostViewController:(NSNumber *)ownerId {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *viewController =(UIViewController *)[_screensAssembly createPostViewController:ownerId];
        BaseNavigationController *controller = [[BaseNavigationController alloc] initWithRootViewController:viewController];
        [self.topViewController presentViewController:controller animated:YES completion:nil];
    });
}

- (void)dismissCreatePostViewController:(NSNumber *)isPostPublished {
    dispatch_async(dispatch_get_main_queue(), ^{
        BaseNavigationController *navigationController = [self navigationController];
        UIViewController *topViewController = navigationController.viewControllers.lastObject;
        if ([topViewController conformsToProtocol:@protocol(ViewControllerActionsExtension)]) {
            id<ViewControllerActionsExtension> extension = (id<ViewControllerActionsExtension>)topViewController;
            extension.needsUpdateContentOnAppear = isPostPublished.boolValue;
        }
        if (navigationController.presentedViewController) {
            [navigationController dismissViewControllerAnimated:YES completion:nil];
        }
    });
}

- (void)showDialogViewController:(NSNumber *)userId {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
       /*
        if ([self canIgnorePushingViewController:[DialogViewController class]]) {
            return;
        }
        */
        DialogViewControllerAllocator *viewControllerAllocator =(DialogViewControllerAllocator *)[_screensAssembly dialogViewController:userId];
        UIViewController *viewController = (UIViewController *)[viewControllerAllocator getViewController];
        [self pushViewController:viewController clean:NO];
    });
}

- (void)showMainViewController {
    NSCParameterAssert(_dialogsManager);
    if ([self.window.rootViewController isEqual:_mainViewController]) {
        return;
    }
    [_dialogsManager initialize];
    MenuViewController *menuViewController = (MenuViewController *)_mainViewController.leftViewController;
    NSCAssert([menuViewController isKindOfClass:[MenuViewController class]], @"menuViewController has unknown class: %@", menuViewController);
    if ([menuViewController isKindOfClass:[MenuViewController class]]) {
        menuViewController.viewModel = [_screensAssembly.viewModelsAssembly menuScreenViewModel];
    }
    self.window.rootViewController = _mainViewController;
}

- (void)showMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mainViewController showLeftViewAnimated:YES completionHandler:^{}];
    });
}

- (void)showPhotoAlbumsViewController:(NSNumber *)ownerId push:(NSNumber *)push {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        PhotoAlbumsViewController *viewController =(PhotoAlbumsViewController *)[_screensAssembly photoAlbumsViewController:ownerId];
        viewController.pushed = push.boolValue;
        [self pushViewController:viewController clean:!push.boolValue];
    });
}

- (void)showGalleryViewControllerWithOwnerId:(NSNumber *)ownerId albumId:(id)albumId {
    dispatch_async(dispatch_get_main_queue(), ^{
        GalleryViewController *viewController =(GalleryViewController *)[_screensAssembly galleryViewController:ownerId albumId:albumId];
        [self pushViewController:viewController clean:NO];
    });
}

- (void)showImagesViewerViewControllerWithOwnerId:(NSNumber *)ownerId albumId:(NSNumber *)albumId photoId:(NSNumber *)photoId {
    dispatch_async(dispatch_get_main_queue(), ^{
        ImagesViewerViewController *viewController =(ImagesViewerViewController *)[_screensAssembly imagesViewerViewController:ownerId albumId:albumId photoId:photoId];
        [self pushViewController:viewController clean:NO];
    });
}

- (void)showImagesViewerViewControllerWithOwnerId:(NSNumber *)ownerId postId:(NSNumber *)postId photoIndex:(NSNumber *)photoIndex {
    dispatch_async(dispatch_get_main_queue(), ^{
        ImagesViewerViewController *viewController =(ImagesViewerViewController *)[_screensAssembly imagesViewerViewController:ownerId postId:postId photoIndex:photoIndex];
        [self pushViewController:viewController clean:NO];
    });
}


- (void)showDetailPhotoViewControllerWithOwnerId:(NSNumber *)ownerId photoId:(NSNumber *)photoId {
    dispatch_async(dispatch_get_main_queue(), ^{
        DetailPhotoViewController *viewController =(DetailPhotoViewController *)[_screensAssembly detailPhotoViewController:ownerId
                                                                                                                    photoId:photoId];
        [self pushViewController:viewController clean:NO];
    });
}

- (void)showNewsViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        if ([self canIgnorePushingViewController:[NewsViewController class]]) {
            return;
        }
        NewsViewController *viewController =(NewsViewController *)[_screensAssembly newsViewController];
        [self pushViewController:viewController];
    });
}

- (void)showAnswersViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        if ([self canIgnorePushingViewController:[AnswersViewController class]]) {
            return;
        }
        AnswersViewController *viewController =(AnswersViewController *)[_screensAssembly answersViewController];
        [self pushViewController:viewController];
    });
}

- (void)showGroupsViewController:(NSNumber *)userId {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        if ([self canIgnorePushingViewController:[GroupsViewController class]]) {
            return;
        }
        GroupsViewController *viewController =(GroupsViewController *)[_screensAssembly groupsViewController:userId];
        [self pushViewController:viewController];
    });
}

- (void)showBookmarksViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        if ([self canIgnorePushingViewController:[BookmarksViewController class]]) {
            return;
        }
        BookmarksViewController *viewController =(BookmarksViewController *)[_screensAssembly bookmarksViewController];
        [self pushViewController:viewController];
    });
}

- (void)showVideosViewController:(NSNumber *)ownerId {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        if ([self canIgnorePushingViewController:[VideosViewController class]]) {
            return;
        }
        VideosViewController *viewController =(VideosViewController *)[_screensAssembly videosViewController:ownerId];
        [self pushViewController:viewController];
    });
}

- (void)showDocumentsViewController:(NSNumber *)ownerId {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        if ([self canIgnorePushingViewController:[VideosViewController class]]) {
            return;
        }
        DocumentsViewController *viewController =(DocumentsViewController *)[_screensAssembly documentsViewController:ownerId];
        [self pushViewController:viewController];
    });
}

- (void)showSettingsViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        if ([self canIgnorePushingViewController:[SettingsViewController class]]) {
            return;
        }
        SettingsViewController *viewController =(SettingsViewController *)[_screensAssembly settingsViewController];
        [self pushViewController:viewController];
    });
}

- (void)showDetailVideoViewControllerWithOwnerId:(NSNumber *)ownerId videoId:(NSNumber *)videoId {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        if ([self canIgnorePushingViewController:[DetailVideoViewController class]]) {
            return;
        }
        DetailVideoViewController *viewController =(DetailVideoViewController *)[_screensAssembly detailVideoViewController:ownerId videoId:videoId];
        [self pushViewController:viewController clean:NO];
    });
}

- (void)showVideoPlayerViewControllerWithVideo:(Video *)video {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *viewController = [_screensAssembly videoPlayerViewController:video];
        [self pushViewController:viewController clean:NO];
    });
}

- (UIViewController *)topViewController {
    UIViewController *viewController = [self navigationController].viewControllers.lastObject;
    if (viewController.presentedViewController) {
        return viewController.presentedViewController;
    }
    return viewController;
}

#pragma mark - Private Methods
- (BaseNavigationController *)navigationController {
    return(BaseNavigationController *)_mainViewController.rootViewController;
}

- (void)closeMenu {
    if (![self.mainViewController isLeftViewHidden]) {
        [self.mainViewController hideLeftViewAnimated];
    }
}

- (BOOL)canIgnorePushingViewController:(Class)cls {
    if ([[self.navigationController.topViewController class] isEqual:cls]) {
        return YES;
    }
    return NO;
}

- (void)pushViewController:(UIViewController *)viewController {
    [self pushViewController:viewController clean:YES];
}

- (void)pushViewController:(UIViewController *)viewController clean:(BOOL)clean {
    if ([self allowReplaceWithViewController:viewController]) {
        self.navigationController.viewControllers = @[viewController];
    }
    else {
        [self.navigationController pushViewController:viewController animated:(clean)?NO:YES completion:^{
            if (clean && self.navigationController.viewControllers.count > 1) {
                self.navigationController.viewControllers = @[viewController];
            }
        }];
    }
}

- (BOOL)allowReplaceWithViewController:(UIViewController *)viewController {
    if (!self.navigationController.viewControllers.count) {
        return YES;
    }
    if (self.navigationController.viewControllers.count == 1 &&
        [self.navigationController.viewControllers.firstObject isKindOfClass:[AuthorizationViewController class]]) {
        return YES;
    }
    return NO;
}

@end
