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

static const NSInteger kBatchSize = 20;

@interface NewsViewController () <ASCollectionDelegate, ASCollectionDataSource>
@property (strong, nonatomic) id<NewsHandlerProtocol> handler;
@property (assign, nonatomic) BOOL updating;
@property (strong, nonatomic) id<PythonBridge> pythonBridge;
@property (strong, nonatomic) id<NodeFactory> nodeFactory;
@end

@implementation NewsViewController {
    ASCollectionNode *_collectionNode;
    NSMutableArray *_data;
}

- (instancetype)initWithPythonBridge:(id<PythonBridge>)pythonBridge
                         nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(pythonBridge);
    NSCParameterAssert(nodeFactory);
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    _collectionNode = [[ASCollectionNode alloc] initWithCollectionViewLayout:layout];
    
    self = [super initWithNode:_collectionNode];
    
    if (self) {
        _pythonBridge = pythonBridge;
        _nodeFactory = nodeFactory;
        _collectionNode.backgroundColor = [UIColor whiteColor];
        _collectionNode.accessibilityIdentifier = @"Cat deals list";
        
        ASRangeTuningParameters preloadTuning;
        preloadTuning.leadingBufferScreenfuls = 2;
        preloadTuning.trailingBufferScreenfuls = 1;
        [_collectionNode setTuningParameters:preloadTuning forRangeType:ASLayoutRangeTypePreload];
        
        ASRangeTuningParameters displayTuning;
        displayTuning.leadingBufferScreenfuls = 1;
        displayTuning.trailingBufferScreenfuls = 0.5;
        [_collectionNode setTuningParameters:displayTuning forRangeType:ASLayoutRangeTypeDisplay];
        
        [_collectionNode registerSupplementaryNodeOfKind:UICollectionElementKindSectionHeader];
        [_collectionNode registerSupplementaryNodeOfKind:UICollectionElementKindSectionFooter];
        
        _data = [[NSMutableArray alloc] init];
        self.title = @"VK Wall";
        _collectionNode.dataSource = self;
        _collectionNode.delegate = self;
    }
    
    return self;
}

- (void)viewDidLoad {
    NSCParameterAssert(_pythonBridge);
    [super viewDidLoad];
    _collectionNode.leadingScreensForBatching = 2;
    _handler = [_pythonBridge handlerWithProtocol:@protocol(NewsHandlerProtocol)];
    self.updating = YES;
    [self fetchMorePostsWithCompletion:^(BOOL finished) {
        self.updating = NO;
    }];
    
    UIButton *button = [UIButton new];
    [button addTarget:self action:@selector(menuTapped:) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"menuIcon.phg"] forState:UIControlStateNormal];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    [self.navigationItem setLeftBarButtonItem:backButton];
}

#pragma mark - Data Model
- (void)fetchMorePostsWithCompletion:(void (^)(BOOL))completion
{
    [self appendMoreItems:kBatchSize completion:completion];
}

- (void)appendMoreItems:(NSInteger)numberOfNewItems completion:(void (^)(BOOL))completion
{
    [self getWall:^(NSArray *posts) {
        [_collectionNode performBatchAnimated:YES updates:^{
            [_data addObjectsFromArray:posts];
            NSArray *addedIndexPaths = [self indexPathsForObjects:posts];
            [_collectionNode insertItemsAtIndexPaths:addedIndexPaths];
        } completion:completion];
    }
           offset:_data.count];
}

- (NSArray *)indexPathsForObjects:(NSArray *)data
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSInteger section = 0;
    for (WallPost *viewModel in data) {
        NSInteger item = [_data indexOfObject:viewModel];
        NSAssert(item < [_data count] && item != NSNotFound, @"Item should be in _data");
        [indexPaths addObject:[NSIndexPath indexPathForItem:item inSection:section]];
    }
    return indexPaths;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [_collectionNode.view.collectionViewLayout invalidateLayout];
}

#pragma mark - Observers

- (IBAction)menuTapped:(id)sender {
    [_handler menuTapped];
}

#pragma mark - ASCollectionNodeDelegate / ASCollectionNodeDataSource

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return ^{
        WallPost *post = _data[indexPath.row];
        ASCellNode *node = (ASCellNode *)[_nodeFactory nodeForItem:post];
        return node;
    };
}

- (id)collectionNode:(ASCollectionNode *)collectionNode nodeModelForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return _data[indexPath.item];
}

- (ASCellNode *)collectionNode:(ASCollectionNode *)collectionNode nodeForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionFooter] && indexPath.section == 0) {
        return [[LoadingNode alloc] init];
    }
    return nil;
}

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ASSizeRange result = ASSizeRangeUnconstrained;
    result.min.width = self.view.width;
    result.max.width = self.view.width;
    return result;
}

- (NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
    return [_data count];
}

- (NSInteger)numberOfSectionsInCollectionNode:(ASCollectionNode *)collectionNode
{
    return 1;
}

- (void)collectionNode:(ASCollectionNode *)collectionNode willBeginBatchFetchWithContext:(ASBatchContext *)context
{
    DDLogInfo(@"\n\n\nPre fetching$$$\n\n\n");
    if (self.updating) {
        [context completeBatchFetching:YES];
        return;
    }
    self.updating = YES;
    [self fetchMorePostsWithCompletion:^(BOOL finished){
        DDLogInfo(@"\n\n\nFetching completed!$$$\n\n\n");
        [context completeBatchFetching:YES];
        self.updating = NO;
    }];
}

#pragma mark - ASCollectionDelegateFlowLayout

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode sizeRangeForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return ASSizeRangeUnconstrained;
    } else {
        return ASSizeRangeZero;
    }
}

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode sizeRangeForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return ASSizeRangeUnconstrained;
    } else {
        return ASSizeRangeZero;
    }
}

#pragma mark - Private
- (void)getWall:(void(^)(NSArray *posts))completion
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
