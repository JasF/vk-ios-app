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


static const NSTimeInterval kWebResponseDelay = 1.0;
static const BOOL kSimulateWebResponse = YES;
static const NSInteger kBatchSize = 20;

static const CGFloat kHorizontalSectionPadding = 10.0f;

@interface NewsViewController ()
@property (strong, nonatomic) id<NewsHandlerProtocol> handler;
@property (nonatomic, strong) ASTableNode *tableNode;
@property (nonatomic, strong) NSMutableArray *socialAppDataSource;
@end

@implementation NewsViewController {
    ASCollectionNode *_collectionNode;
    NSMutableArray *_data;
}

- (instancetype)init {
    //_tableNode = [[ASTableNode alloc] initWithStyle:UITableViewStylePlain];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    _collectionNode = [[ASCollectionNode alloc] initWithCollectionViewLayout:layout];
    
    self = [super initWithNode:_collectionNode];
    
    if (self) {
        
        _collectionNode.dataSource = self;
        _collectionNode.delegate = self;
        _collectionNode.backgroundColor = [UIColor grayColor];
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
        
        /*
        _tableNode.delegate = self;
        _tableNode.dataSource = self;
        _tableNode.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        */
        self.title = @"VK Wall";
    }
    
    return self;
}

- (void)viewDidLoad {
    _pythonBridge = [AppDelegate shared].pythonBridge;
    NSCParameterAssert(_pythonBridge);
    [super viewDidLoad];
    _collectionNode.leadingScreensForBatching = 2;
    //self.tableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
    _handler = [_pythonBridge handlerWithProtocol:@protocol(NewsHandlerProtocol)];
    [self fetchMorePostsWithCompletion:nil];
    // Do any additional setup after loading the view.
}

#pragma mark - Data Model
- (void)fetchMorePostsWithCompletion:(void (^)(BOOL))completion
{
    /*
    if (kSimulateWebResponse) {
        __weak typeof(self) weakSelf = self;
        void(^mockWebService)() = ^{
            NSLog(@"ViewController \"got data from a web service\"");
            ViewController *strongSelf = weakSelf;
            if (strongSelf != nil)
            {
                [strongSelf appendMoreItems:kBatchSize completion:completion];
            }
            else {
                NSLog(@"ViewController is nil - won't update collection");
            }
        };
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kWebResponseDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), mockWebService);
    } else {
    }
    */
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
    }];
    /*
    NSArray *newData = [self getMoreData:numberOfNewItems];
     */
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

#pragma mark - ASTableNode

/*
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
*/

#pragma mark - Observers

- (IBAction)menuTapped:(id)sender {
    [_handler menuTapped];
}

#pragma mark - ASCollectionNodeDelegate / ASCollectionNodeDataSource

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return ^{
        WallPost *post = _data[indexPath.row];
        return [[WallPostNode alloc] initWithPost:post];
    };
}

- (id)collectionNode:(ASCollectionNode *)collectionNode nodeModelForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return _data[indexPath.item];
}

- (ASCellNode *)collectionNode:(ASCollectionNode *)collectionNode nodeForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionHeader] && indexPath.section == 0) {
        return [[BlurbNode alloc] init];
    } else if ([kind isEqualToString:UICollectionElementKindSectionFooter] && indexPath.section == 0) {
        return [[LoadingNode alloc] init];
    }
    return nil;
}

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat collectionViewWidth = CGRectGetWidth(self.view.frame) - 2 * kHorizontalSectionPadding;
    CGFloat oneItemWidth = self.view.width;
    NSInteger numColumns = floor(collectionViewWidth / oneItemWidth);
    // Number of columns should be at least 1
    numColumns = MAX(1, numColumns);
    
    CGFloat totalSpaceBetweenColumns = (numColumns - 1) * kHorizontalSectionPadding;
    CGFloat itemWidth = ((collectionViewWidth - totalSpaceBetweenColumns) / numColumns);
    CGSize itemSize = CGSizeMake(itemWidth, 250);
    return ASSizeRangeMake(itemSize, itemSize);
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
    [self fetchMorePostsWithCompletion:^(BOOL finished){
        [context completeBatchFetching:YES];
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
- (void)getWall {
    [self getWall:^(NSArray *posts) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.socialAppDataSource = [posts mutableCopy];
            [self.tableNode reloadData];
            NSLog(@"\n\n\n$$$$$ TABLE VIEW RELOADED $$$$$\n\n\n");
        });
    }];
}

- (void)getWall:(void(^)(NSArray *posts))completion {
    NSDictionary *wallData = [_handler getWall];
    [self processWallData:wallData
               completion:completion];
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
            if (completion) {
                completion(posts);
            }
        });
    });
    
}

@end
