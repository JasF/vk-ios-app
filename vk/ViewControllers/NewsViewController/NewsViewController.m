//
//  NewsViewController.m
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "NewsViewController.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "Post.h"
#import "PostNode.h"
#import "VKSdkManager.h"
#import <VK-ios-sdk/VKSdk.h>
#import "WallPost.h"
#import "WallPostNode.h"
#import "User.h"
#import "BlurbNode.h"
#import "LoadingNode.h"
#import "AppDelegate.h"

@interface NewsViewController () <BaseCollectionViewControllerDataSource>
@property (strong, nonatomic) id<NewsHandlerProtocol> handler;
@property (strong, nonatomic) id<PythonBridge> pythonBridge;
@property (strong, nonatomic) id<WallService> wallService;
@end

@implementation NewsViewController {
}

- (instancetype)initWithPythonBridge:(id<PythonBridge>)pythonBridge
                         nodeFactory:(id<NodeFactory>)nodeFactory
                         wallService:(id<WallService>)wallService {
    NSCParameterAssert(pythonBridge);
    NSCParameterAssert(nodeFactory);
    NSCParameterAssert(wallService);
    _pythonBridge = pythonBridge;
    self.dataSource = self;
    _wallService = wallService;
    self = [super initWithNodeFactory:nodeFactory];
    if (self) {
        self.title = @"VK Wall";
    }
    return self;
}

- (void)viewDidLoad {
    NSCParameterAssert(_pythonBridge);
    [super viewDidLoad];
    _handler = [_pythonBridge handlerWithProtocol:@protocol(NewsHandlerProtocol)];
    [self addMenuIconWithTarget:self action:@selector(menuTapped:)];
}


#pragma mark - Observers

- (IBAction)menuTapped:(id)sender {
    [_handler menuTapped];
}

#pragma mark - BaseCollectionViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    [_wallService getWallPostsWithOffset:offset
                              completion:completion];
}

@end
