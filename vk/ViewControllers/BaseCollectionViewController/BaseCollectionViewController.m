//
//  BaseCollectionViewController.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseCollectionViewController.h"
#import "LoadingNode.h"

static const NSInteger kBatchSize = 20;

@interface BaseCollectionViewController () <A_SCollectionDelegate, A_SCollectionDataSource>
@property A_SCollectionNode *collectionNode;
@property NSMutableArray *data;
@property id<NodeFactory> nodeFactory;
@property (assign, nonatomic) BOOL updating;
@end

@implementation BaseCollectionViewController {
    BOOL _initiallyUpdated;
}

- (id)initWithNodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(nodeFactory);
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    _collectionNode = [[A_SCollectionNode alloc] initWithCollectionViewLayout:layout];
    self = [super initWithNode:_collectionNode];
    if (self) {
        _nodeFactory = nodeFactory;
        _collectionNode.backgroundColor = [UIColor whiteColor];
        _collectionNode.accessibilityIdentifier = NSStringFromClass([self class]);
        
        A_SRangeTuningParameters preloadTuning;
        preloadTuning.leadingBufferScreenfuls = 2;
        preloadTuning.trailingBufferScreenfuls = 1;
        [_collectionNode setTuningParameters:preloadTuning forRangeType:A_SLayoutRangeTypePreload];
        
        A_SRangeTuningParameters displayTuning;
        displayTuning.leadingBufferScreenfuls = 1;
        displayTuning.trailingBufferScreenfuls = 0.5;
        [_collectionNode setTuningParameters:displayTuning forRangeType:A_SLayoutRangeTypeDisplay];
        
        [_collectionNode registerSupplementaryNodeOfKind:UICollectionElementKindSectionHeader];
        [_collectionNode registerSupplementaryNodeOfKind:UICollectionElementKindSectionFooter];
        
        _data = [[NSMutableArray alloc] init];
        _collectionNode.dataSource = self;
        _collectionNode.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _collectionNode.leadingScreensForBatching = 2;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_initiallyUpdated) {
        _initiallyUpdated = YES;
        self.updating = YES;
        [self fetchMorePostsWithCompletion:^(BOOL finished) {
            self.updating = NO;
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data Model
- (void)fetchMorePostsWithCompletion:(void (^)(BOOL))completion
{
    [self appendMoreItems:kBatchSize completion:completion];
}

- (void)appendMoreItems:(NSInteger)numberOfNewItems completion:(void (^)(BOOL))completion
{
    if ([_dataSource respondsToSelector:@selector(getModelObjets:offset:)]) {
        @weakify(self);
        [_dataSource getModelObjets:^(NSArray *objects) {
            @strongify(self);
            [self.collectionNode performBatchAnimated:YES updates:^{
                @strongify(self);
                [self.data addObjectsFromArray:objects];
                NSArray *addedIndexPaths = [self indexPathsForObjects:objects];
                [self.collectionNode insertItemsAtIndexPaths:addedIndexPaths];
            } completion:completion];
        }
                             offset:self.data.count];
    }
}

- (NSArray *)indexPathsForObjects:(NSArray *)data
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSInteger section = 0;
    for (id viewModel in data) {
        NSInteger item = [_data indexOfObject:viewModel];
        NSAssert(item < [_data count] && item != NSNotFound, @"Item should be in _data");
        [indexPaths addObject:[NSIndexPath indexPathForItem:item inSection:section]];
    }
    return indexPaths;
}

#pragma mark - A_SCollectionNodeDelegate / A_SCollectionNodeDataSource

- (A_SCellNodeBlock)collectionNode:(A_SCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return ^{
        id object = _data[indexPath.row];
        A_SCellNode *node = (A_SCellNode *)[_nodeFactory nodeForItem:object];
        return node;
    };
}

- (id)collectionNode:(A_SCollectionNode *)collectionNode nodeModelForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return _data[indexPath.item];
}

- (A_SCellNode *)collectionNode:(A_SCollectionNode *)collectionNode nodeForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionFooter] && indexPath.section == 0) {
        return [[LoadingNode alloc] init];
    }
    return nil;
}

- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    A_SSizeRange result = A_SSizeRangeUnconstrained;
    result.min.width = self.view.width;
    result.max.width = self.view.width;
    return result;
}

- (NSInteger)collectionNode:(A_SCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
    return [_data count];
}

- (NSInteger)numberOfSectionsInCollectionNode:(A_SCollectionNode *)collectionNode
{
    return 1;
}

- (void)collectionNode:(A_SCollectionNode *)collectionNode willBeginBatchFetchWithContext:(A_SBatchContext *)context
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

#pragma mark - Layouting
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [_collectionNode.view.collectionViewLayout invalidateLayout];
}

#pragma mark - A_SCollectionDelegateFlowLayout
- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode sizeRangeForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return A_SSizeRangeUnconstrained;
    } else {
        return A_SSizeRangeZero;
    }
}

- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode sizeRangeForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return A_SSizeRangeUnconstrained;
    } else {
        return A_SSizeRangeZero;
    }
}

#pragma mark - Public Methods
- (void)addMenuIconWithTarget:(id)target action:(SEL)action {
    UIButton *button = [UIButton new];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"menuIcon.phg"] forState:UIControlStateNormal];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    [self.navigationItem setLeftBarButtonItem:backButton];
}

@end