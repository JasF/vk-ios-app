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

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASAssert.h>

@interface NewsViewController ()
@property (strong, nonatomic) id<NewsHandlerProtocol> handler;
@property (nonatomic, strong) ASTableNode *tableNode;
@property (nonatomic, strong) NSMutableArray *socialAppDataSource;
@end

@implementation NewsViewController

- (instancetype)init
{
    _tableNode = [[ASTableNode alloc] initWithStyle:UITableViewStylePlain];
    
    self = [super initWithNode:_tableNode];
    
    if (self) {
        
        _tableNode.delegate = self;
        _tableNode.dataSource = self;
        _tableNode.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        self.title = @"VK Wall";
        
        [self createSocialAppDataSource];
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

- (void)createSocialAppDataSource
{
    _socialAppDataSource = [[NSMutableArray alloc] init];
    
        Post *newPost = [[Post alloc] init];
        newPost.name = @"Apple Guy";
        newPost.username = @"@appleguy";
        newPost.photo = @"https://avatars1.githubusercontent.com/u/565251?v=3&s=96";
        newPost.post = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.";
        newPost.time = @"3s";
        newPost.media = @"";
        newPost.via = 0;
        newPost.likes = arc4random_uniform(74);
        newPost.comments = arc4random_uniform(40);
        [_socialAppDataSource addObject:newPost];
        
        newPost = [[Post alloc] init];
        newPost.name = @"Huy Nguyen";
        newPost.username = @"@nguyenhuy";
        newPost.photo = @"https://avatars2.githubusercontent.com/u/587874?v=3&s=96";
        newPost.post = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
        newPost.time = @"1m";
        newPost.media = @"";
        newPost.via = 1;
        newPost.likes = arc4random_uniform(74);
        newPost.comments = arc4random_uniform(40);
        [_socialAppDataSource addObject:newPost];
        
        newPost = [[Post alloc] init];
        newPost.name = @"Alex Long Name";
        newPost.username = @"@veryyyylongusername";
        newPost.photo = @"https://avatars1.githubusercontent.com/u/8086633?v=3&s=96";
        newPost.post = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
        newPost.post = [self process:newPost.post];
        newPost.time = @"3:02";
        newPost.media = @"http://www.ngmag.ru/upload/iblock/f93/f9390efc34151456598077c1ba44a94d.jpg";
        newPost.via = 2;
        newPost.likes = arc4random_uniform(74);
        newPost.comments = arc4random_uniform(40);
        [_socialAppDataSource addObject:newPost];
        
        newPost = [[Post alloc] init];
        newPost.name = @"Vitaly Baev";
        newPost.username = @"@vitalybaev";
        newPost.photo = @"https://avatars0.githubusercontent.com/u/724423?v=3&s=96";
        newPost.post = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. https://github.com/facebook/AsyncDisplayKit Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
        newPost.time = @"yesterday";
        newPost.media = @"";
        newPost.via = 1;
        newPost.likes = arc4random_uniform(74);
        newPost.comments = arc4random_uniform(40);
        [_socialAppDataSource addObject:newPost];
    
    NSLog(@"\n\n\n\n\n$$$$$$$$$$ Generating finished! $$$$$$$$$$\n\n\n\n\n");
}

- (void)viewDidLoad {
    NSCParameterAssert(_pythonBridge);
    [super viewDidLoad];
    self.tableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
    _handler = [_pythonBridge handlerWithProtocol:@protocol(NewsHandlerProtocol)];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - ASTableNode


- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Post *post = self.socialAppDataSource[indexPath.row];
    return ^{
        return [[PostNode alloc] initWithPost:post indexPath:indexPath];
    };
}

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
    return self.socialAppDataSource.count;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
