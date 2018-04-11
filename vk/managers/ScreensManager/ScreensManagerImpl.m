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
#import "NewsViewController.h"
#import "BaseNavigationController.h"

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

- (void)showMainViewController {
    if ([self.window.rootViewController isEqual:_mainViewController]) {
        return;
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
