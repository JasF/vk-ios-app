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
#import "ViewController.h"
#import "WallViewController.h"
#import "ChatListViewController.h"
#import "BaseNavigationController.h"
#import "vk-Swift.h"
#import "MenuViewController.h"
#import "ViewModelsAssembly.h"
#import "FriendsViewController.h"
#import "WallPostViewController.h"

@interface ScreensManagerImpl ()
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) id<VKSdkManager> vkSdkManager;
@property (strong, nonatomic) id<PythonBridge> pythonBridge;
@property (strong, nonatomic) ScreensAssembly *screensAssembly;
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
        [self.window makeKeyAndVisible];
    }
}

- (void)showAuthorizationViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
        ViewController *viewController =(ViewController *)[self.screensAssembly createViewController];
        [navigationController pushViewController:viewController animated:YES];
    });
}

- (void)showWallViewController {
    [self showWallViewController:@(0)];
}

- (void)showWallViewController:(NSNumber *)userId {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        WallViewController *viewController =(WallViewController *)[_screensAssembly wallViewController:userId];
        [self pushViewController:viewController];
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

- (void)showFriendsViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        if ([self canIgnorePushingViewController:[FriendsViewController class]]) {
            return;
        }
        FriendsViewController *viewController =(FriendsViewController *)[_screensAssembly friendsViewController];
        [self pushViewController:viewController];
    });
}

- (void)showDialogViewController:(NSNumber *)userId {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showMainViewController];
        [self closeMenu];
        if ([self canIgnorePushingViewController:[DialogViewController class]]) {
            return;
        }
        DialogViewController *viewController =(DialogViewController *)[_screensAssembly dialogViewController:userId];
        [self pushViewController:viewController clean:NO];
    });
}

- (void)showMainViewController {
    if ([self.window.rootViewController isEqual:_mainViewController]) {
        return;
    }
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

#pragma mark - Private Methods
- (ViewController *)createViewController {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"ViewController"];
    viewController.vkManager = [self vkSdkManager];
    viewController.handler = [self.pythonBridge handlerWithProtocol:@protocol(AuthorizationHandlerProtocolDelegate)];
    viewController.pythonBridge = self.pythonBridge;
    return viewController;
}

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
        [self.navigationController pushViewController:viewController animated:YES completion:^{
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
        [self.navigationController.viewControllers.firstObject isKindOfClass:[ViewController class]]) {
        return YES;
    }
    return NO;
}

@end
