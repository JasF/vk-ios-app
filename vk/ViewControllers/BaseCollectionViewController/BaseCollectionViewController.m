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

@interface BaseCollectionViewController () <ASCollectionDelegate, ASCollectionDataSource>
@property NSMutableArray *data;
@property (assign, nonatomic) BOOL updating;
@end

@implementation BaseCollectionViewController {
    BOOL _initiallyUpdated;
}

- (id)initWithNodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(nodeFactory);
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    _collectionNode = [[ASCollectionNode alloc] initWithCollectionViewLayout:layout];
    self = [super initWithNode:_collectionNode];
    if (self) {
        _nodeFactory = nodeFactory;
        _collectionNode.backgroundColor = [UIColor whiteColor];
        _collectionNode.accessibilityIdentifier = NSStringFromClass([self class]);
        
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
    [self appendMoreItems:numberOfNewItems
                   offset:self.data.count
               withReload:NO
               completion:completion];
}

- (void)appendMoreItems:(NSInteger)numberOfNewItems
                 offset:(NSInteger)offset
             withReload:(BOOL)withReload
             completion:(void (^)(BOOL))completion {
    if ([_dataSource respondsToSelector:@selector(getModelObjets:offset:)]) {
        @weakify(self);
        [_dataSource getModelObjets:^(NSArray *objects) {
            @strongify(self);
            if (withReload) {
                [self.data removeAllObjects];
                [self.data addObjectsFromArray:objects];
                [self.collectionNode reloadData];
                if (completion) {
                    completion(YES);
                }
            }
            else {
                [self.collectionNode performBatchAnimated:YES updates:^{
                    @strongify(self);
                    [self performBatchAnimated:YES];
                    [self.data addObjectsFromArray:objects];
                    NSArray *addedIndexPaths = [self indexPathsForObjects:objects];
                    [self.collectionNode insertItemsAtIndexPaths:addedIndexPaths];
                } completion:completion];
            }
        }
                             offset:offset];
    }
}

- (void)performBatchAnimated:(BOOL)animated {
}

- (NSArray *)indexPathsForObjects:(NSArray *)data
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSInteger section = [self numberOfSectionsInCollectionNode:self.collectionNode] - 1;
    for (id viewModel in data) {
        NSInteger item = [_data indexOfObject:viewModel];
        NSAssert(item < [_data count] && item != NSNotFound, @"Item should be in _data");
        [indexPaths addObject:[NSIndexPath indexPathForItem:item inSection:section]];
    }
    return indexPaths;
}

#pragma mark - ASCollectionDelegate, ASCollectionDataSource

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
    @weakify(self);
    return ^{
        @strongify(self);
        id object = self.data[indexPath.row];
        /*
        NSArray *colors = @[[UIColor greenColor], [UIColor redColor], [UIColor brownColor], [UIColor cyanColor]];
        ASCellNode *node = [ASCellNode new];
        node.style.width = ASDimensionMakeWithPoints(40.f);
        node.style.height = ASDimensionMakeWithPoints(40.f);
        node.backgroundColor = [colors[arc4random()%3] colorWithAlphaComponent:0.1];
        */
        ASCellNode *node = (ASCellNode *)[self.nodeFactory nodeForItem:object];
        return node;
    };
}

- (id)collectionNode:(ASCollectionNode *)collectionNode nodeModelForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return _data[indexPath.item];
}

- (ASCellNode *)collectionNode:(ASCollectionNode *)collectionNode nodeForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:UICollectionElementKindSectionFooter] && indexPath.section == ([self numberOfSectionsInCollectionNode:self.collectionNode] > -1)) {
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

#pragma mark - Layouting
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [_collectionNode.view.collectionViewLayout invalidateLayout];
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

#pragma mark - Public Methods
- (NSArray *)objectsArray {
    return _data;
}

- (void)addMenuIconWithTarget:(id)target action:(SEL)action {
    UIButton *button = [UIButton new];
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"menuIcon"] forState:UIControlStateNormal];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.leftBarButtonItem = backButton;
    [button sizeToFit];
}

- (void)simpleReloadCollectionView {
    [self.collectionNode reloadData];
}

- (void)reloadData {
    self.updating = YES;
    [self appendMoreItems:self.data.count
                   offset:0
               withReload:YES
               completion:^(BOOL finished) {
                   self.updating = NO;
               }];
}

@end
