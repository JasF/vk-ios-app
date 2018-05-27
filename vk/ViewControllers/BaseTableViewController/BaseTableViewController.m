//
//  BaseTableViewController.m
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseTableViewController.h"

#import "BaseTableViewController.h"
#import "LoadingNode.h"

static const NSInteger kBatchSize = 20;

@interface BaseTableViewController () <ASTableDelegate, ASTableDataSource>
@property NSMutableArray *data;
@property (assign, nonatomic) BOOL updating;
@property NSIndexPath *selectedIndexPath;
@end

@implementation BaseTableViewController {
    BOOL _initiallyUpdated;
}

- (id)initWithNodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(nodeFactory);
    _tableNode = [[ASTableNode alloc] init];
    self = [super initWithNode:_tableNode];
    if (self) {
        self.nodeFactory = nodeFactory;
        _tableNode.backgroundColor = [UIColor whiteColor];
        _tableNode.accessibilityIdentifier = NSStringFromClass([self class]);
        
        ASRangeTuningParameters preloadTuning;
        preloadTuning.leadingBufferScreenfuls = 2;
        preloadTuning.trailingBufferScreenfuls = 1;
        [_tableNode setTuningParameters:preloadTuning forRangeType:ASLayoutRangeTypePreload];
        
        ASRangeTuningParameters displayTuning;
        displayTuning.leadingBufferScreenfuls = 1;
        displayTuning.trailingBufferScreenfuls = 0.5;
        [_tableNode setTuningParameters:displayTuning forRangeType:ASLayoutRangeTypeDisplay];
        
        _data = [[NSMutableArray alloc] init];
        _tableNode.dataSource = self;
        _tableNode.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _tableNode.leadingScreensForBatching = 2;
    _tableNode.view.separatorColor = [UIColor clearColor];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (self.selectedIndexPath) {
        [self.tableNode deselectRowAtIndexPath:self.selectedIndexPath animated:NO];
        self.selectedIndexPath = nil;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_initiallyUpdated) {
        _initiallyUpdated = YES;
        self.updating = YES;
        [self fetchMoreItemsWithCompletion:^(BOOL finished) {
            self.updating = NO;
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Data Model
- (void)fetchMoreItemsWithCompletion:(void (^)(BOOL))completion
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
                [self.tableNode reloadData];
                if (completion) {
                    completion(YES);
                }
            }
            else {
                [self.tableNode performBatchAnimated:NO updates:^{
                    @strongify(self);
                    [self.data addObjectsFromArray:objects];
                    [self performBatchAnimated:YES];
                    NSArray *addedIndexPaths = [self indexPathsForObjects:objects];
                    [self.tableNode insertRowsAtIndexPaths:addedIndexPaths withRowAnimation:UITableViewRowAnimationFade];
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
    NSInteger section = [self numberOfSectionsInTableNode:self.tableNode] - 1;
    for (id viewModel in data) {
        NSInteger item = [_data indexOfObject:viewModel];
        NSAssert(item < [_data count] && item != NSNotFound, @"Item should be in _data");
        [indexPaths addObject:[NSIndexPath indexPathForItem:item inSection:section]];
    }
    return indexPaths;
}

#pragma mark - ASTableDelegate, ASTableDataSource

- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
    @weakify(self);
    return ^{
        @strongify(self);
        if (indexPath.row >= self.data.count) {
            return [ASCellNode new];
        }
        id object = self.data[indexPath.row];
        ASCellNode *node = (ASCellNode *)[self.nodeFactory nodeForItem:object];
        return node;
    };
}

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
    return [_data count];
}

- (NSInteger)numberOfSectionsInTableNode:(ASTableNode *)tableNode
{
    return 1;
}

- (void)tableNode:(ASTableNode *)tableNode willBeginBatchFetchWithContext:(ASBatchContext *)context {
    
    if (self.updating) {
        [context completeBatchFetching:YES];
        return;
    }
    self.updating = YES;
    [self fetchMoreItemsWithCompletion:^(BOOL finished){
        [context completeBatchFetching:YES];
        self.updating = NO;
    }];
}

- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndexPath = indexPath;
}

#pragma mark - Public Methods
- (NSArray *)objectsArray {
    return _data;
}

- (void)simpleReloadTableView {
    [self.tableNode reloadData];
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
