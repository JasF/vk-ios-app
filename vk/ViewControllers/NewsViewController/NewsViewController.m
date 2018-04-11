//
//  NewsViewController.m
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "NewsViewController.h"
#import "Post.h"
#import "PostNode.h"
#import "VKSdkManager.h"
#import <VK-ios-sdk/VKSdk.h>
#import "WallPost.h"
#import "WallPostNode.h"
#import "User.h"

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASAssert.h>

@interface NewsViewController () <ASTableDelegate, ASTableDataSource>
@property (strong, nonatomic) id<NewsHandlerProtocol> handler;
@property (nonatomic, strong) ASTableNode *tableNode;
@property (nonatomic, strong) NSMutableArray *socialAppDataSource;
@end

@implementation NewsViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    _tableNode = [[ASTableNode alloc] initWithStyle:UITableViewStylePlain];
    
    self = [super initWithNode:_tableNode coder:aDecoder];
    
    if (self) {
        
        _tableNode.delegate = self;
        _tableNode.dataSource = self;
        _tableNode.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.title = @"VK Wall";
    }
    
    return self;
}

#pragma mark - Data Model
- (NSString *)process:(NSString *)string {
    NSString *res = string;
    for (int i=0;i<30;++i) {
        res = [res stringByAppendingString:string];
    }
    return res;
}

- (void)viewDidLoad {
    NSCParameterAssert(_pythonBridge);
    [super viewDidLoad];
    self.tableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
    _handler = [_pythonBridge handlerWithProtocol:@protocol(NewsHandlerProtocol)];
    [self getWall];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - ASTableNode


- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WallPost *post = self.socialAppDataSource[indexPath.row];
    return ^{
        return [[WallPostNode alloc] initWithPost:post];
    };
}

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
    return self.socialAppDataSource.count;
}

#pragma mark - Observers

- (IBAction)menuTapped:(id)sender {
    [_handler menuTapped];
}

#pragma mark - Private
- (void)getWall {
    dispatch_python(^{
        NSDictionary *wallData = [_handler getWall];
        [self processWallData:wallData];
    });
}

- (void)processWallData:(NSDictionary *)wallData {
    NSCAssert([wallData isKindOfClass:[NSDictionary class]] || !wallData, @"wallData unknown type");
    if (![wallData isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSDictionary *response = wallData[@"response"];
    NSArray *users = wallData[@"users"];
    //NSNumber *count = wallData[@"count"];
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
    for (WallPost *post in posts) {
        User *user = usersDictionary[@(post.fromId)];
        if (user) {
            post.firstName = user.first_name;
            post.lastName = user.last_name;
            post.avatarURLString = user.photo_100;
        }
        /*
        user = usersDictionary[@(post.ownerId)];
        if (user) {
            
        }
        */
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.socialAppDataSource = [posts mutableCopy];
        [self.tableNode reloadData];
    });
}

@end
