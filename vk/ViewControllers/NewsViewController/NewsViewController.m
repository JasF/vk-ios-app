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
@end

@implementation NewsViewController {
}

- (instancetype)initWithPythonBridge:(id<PythonBridge>)pythonBridge
                         nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(pythonBridge);
    NSCParameterAssert(nodeFactory);
    _pythonBridge = pythonBridge;
    self.dataSource = self;
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
     NSDictionary *wallData = [_handler getWall:@(offset)];
     [self processWallData:wallData
                completion:completion];
}



- (void)setHistoryFromArray:(NSMutableArray *)array toPost:(WallPost *)post {
    WallPost *history = [array firstObject];
    if (!history) {
        return;
    }
    [array removeObjectAtIndex:0];
    post.history = @[history];
    [self setHistoryFromArray:array toPost:history];
}

- (void)processWallData:(NSDictionary *)wallData
             completion:(void(^)(NSArray *posts))completion {
    dispatch_python(^{
        NSCAssert([wallData isKindOfClass:[NSDictionary class]] || !wallData, @"wallData unknown type");
        if (![wallData isKindOfClass:[NSDictionary class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil);
                }
            });
            return;
        }
        NSDictionary *response = wallData[@"response"];
        NSArray *users = wallData[@"users"];
        NSArray *items = response[@"items"];
        if (![items isKindOfClass:[NSArray class]]) {
            items = @[];
        }
        
        NSArray *posts = [EKMapper arrayOfObjectsFromExternalRepresentation:items
                                                                withMapping:[WallPost objectMapping]];
        
        NSArray *usersObjects = [EKMapper arrayOfObjectsFromExternalRepresentation:users
                                                                       withMapping:[User objectMapping]];
        
        NSMutableDictionary *usersDictionary = [NSMutableDictionary new];
        for (User *user in usersObjects) {
            [usersDictionary setObject:user forKey:@(user.identifier)];
        }
        
        void (^updatePostBlock)(WallPost *post) = ^void(WallPost *post) {
            User *user = usersDictionary[@(ABS(post.from_id))];
            if (user) {
                post.firstName = [user nameString];
                post.avatarURLString = user.photo_100;
            }
        };
        for (WallPost *post in posts) {
            updatePostBlock(post);
            for (WallPost *history in post.history) {
                updatePostBlock(history);
            }
            NSMutableArray *mutableHistory = [post.history mutableCopy];
            [self setHistoryFromArray:mutableHistory toPost:post];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(posts);
            }
        });
    });
}

@end
