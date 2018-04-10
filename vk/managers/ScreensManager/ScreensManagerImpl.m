//
//  ScreensManagerImpl.m
//  vk
//
//  Created by Jasf on 09.04.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import "ScreensManagerImpl.h"
#import "ScreensAssembly.h"
#import "ViewController.h"

@interface ScreensManagerImpl ()
@property (strong, nonatomic) UIViewController *rootViewController;
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
- (UIViewController *)rootViewController {
    return _rootViewController;
}
    
- (void)createWindowIfNeeded {
    if (self.window) {
        return;
    }
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    _rootViewController = [UINavigationController new];
    self.window.rootViewController = _rootViewController;
    [self.window makeKeyAndVisible];
}

- (void)showAuthorizationViewController {
    dispatch_async(dispatch_get_main_queue(), ^{
        UINavigationController *navigationController = (UINavigationController *)self.window.rootViewController;
        ViewController *viewController = [self.screensAssembly createViewController];
        [navigationController pushViewController:viewController animated:YES];
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

@end
