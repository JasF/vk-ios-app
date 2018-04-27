//
//  A_SCollectionModernDataSourceTests.m
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Async_DisplayKit/Async_DisplayKit.h>
#import <Async_DisplayKit/NSIndexSet+A_SHelpers.h>
#import "OCMockObject+A_SAdditions.h"
#import "A_STestCase.h"

@interface A_SCollectionModernDataSourceTests : A_STestCase
@end

@interface A_STestCellNode : A_SCellNode
@end

@interface A_STestSection : NSObject <A_SSectionContext>
@property (nonatomic, readonly) NSMutableArray *nodeModels;
@end

@implementation A_SCollectionModernDataSourceTests {
@private
  id mockDataSource;
  UIWindow *window;
  UIViewController *viewController;
  A_SCollectionNode *collectionNode;
  NSMutableArray<A_STestSection *> *sections;
}

- (void)setUp {
  [super setUp];
  // Default is 2 sections: 2 items in first, 1 item in second.
  sections = [NSMutableArray array];
  [sections addObject:[A_STestSection new]];
  [sections[0].nodeModels addObject:[NSObject new]];
  [sections[0].nodeModels addObject:[NSObject new]];
  [sections addObject:[A_STestSection new]];
  [sections[1].nodeModels addObject:[NSObject new]];
  window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  viewController = [[UIViewController alloc] init];

  window.rootViewController = viewController;
  [window makeKeyAndVisible];
  collectionNode = [[A_SCollectionNode alloc] initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
  collectionNode.frame = viewController.view.bounds;
  collectionNode.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [viewController.view addSubnode:collectionNode];

  mockDataSource = OCMStrictProtocolMock(@protocol(A_SCollectionDataSource));
  [mockDataSource addImplementedOptionalProtocolMethods:
   @selector(numberOfSectionsInCollectionNode:),
   @selector(collectionNode:numberOfItemsInSection:),
   @selector(collectionNode:nodeBlockForItemAtIndexPath:),
   @selector(collectionNode:nodeModelForItemAtIndexPath:),
   @selector(collectionNode:contextForSection:),
   nil];
  [mockDataSource setExpectationOrderMatters:YES];
  
  // NOTE: Adding optionally-implemented methods after this point won't work due to A_SCollectionNode selector caching.
  collectionNode.dataSource = mockDataSource;
}

- (void)tearDown
{
  [collectionNode waitUntilAllUpdatesAreProcessed];
  [super tearDown];
}

#pragma mark - Test Methods

- (void)testInitialDataLoading
{
  [self loadInitialData];
}

- (void)testReloadingAnItem
{
  [self loadInitialData];

  // Reload at (0, 0)
  NSIndexPath *reloadedPath = [NSIndexPath indexPathForItem:0 inSection:0];

  [self performUpdateReloadingSections:nil
                        reloadingItems:@{ reloadedPath: [NSObject new] }
                        reloadMappings:@{ reloadedPath: reloadedPath }
                        insertingItems:nil
                         deletingItems:nil
               skippedReloadIndexPaths:nil];
}

- (void)testInsertingAnItem
{
  [self loadInitialData];

  // Insert at (1, 0)
  NSIndexPath *insertedPath = [NSIndexPath indexPathForItem:0 inSection:1];

  [self performUpdateReloadingSections:nil
                        reloadingItems:nil
                        reloadMappings:nil
                        insertingItems:@{ insertedPath: [NSObject new] }
                         deletingItems:nil
               skippedReloadIndexPaths:nil];
}

- (void)testReloadingAnItemWithACompatibleNodeModel
{
  [self loadInitialData];

  // Reload and delete together, for good measure.
  NSIndexPath *reloadedPath = [NSIndexPath indexPathForItem:1 inSection:0];
  NSIndexPath *deletedPath = [NSIndexPath indexPathForItem:0 inSection:0];

  id nodeModel = [NSObject new];

  // Cell node should get -canUpdateToNodeModel:
  id mockCellNode = [collectionNode nodeForItemAtIndexPath:reloadedPath];
  OCMExpect([mockCellNode canUpdateToNodeModel:nodeModel])
  .andReturn(YES);

  [self performUpdateReloadingSections:nil
                        reloadingItems:@{ reloadedPath: nodeModel }
                        reloadMappings:@{ reloadedPath: [NSIndexPath indexPathForItem:0 inSection:0] }
                        insertingItems:nil
                         deletingItems:@[ deletedPath ]
               skippedReloadIndexPaths:@[ reloadedPath ]];
}

- (void)testReloadingA_Section
{
  [self loadInitialData];

  [self performUpdateReloadingSections:@{ @0: [A_STestSection new] }
                        reloadingItems:nil
                        reloadMappings:nil
                        insertingItems:nil
                         deletingItems:nil
               skippedReloadIndexPaths:nil];
}

#pragma mark - Helpers

- (void)loadInitialData
{
  // Count methods are called twice in a row for first data load.
  // Since -reloadData is routed through our batch update system,
  // the batch update latches the "old data source counts" if needed at -beginUpdates time
  // and then verifies them against the "new data source counts" after the updates.
  // This isn't ideal, but the cost is very small and the system works well.
  for (int i = 0; i < 2; i++) {
    // It reads all the counts
    [self expectDataSourceCountMethods];
  }

  // It reads each section object.
  for (NSInteger section = 0; section < sections.count; section++) {
    [self expectContextMethodForSection:section];
  }

  // It reads the contents for each item.
  for (NSInteger section = 0; section < sections.count; section++) {
    NSArray *nodeModels = sections[section].nodeModels;

    // For each item:
    for (NSInteger i = 0; i < nodeModels.count; i++) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:section];
      [self expectNodeModelMethodForItemAtIndexPath:indexPath nodeModel:nodeModels[i]];
      [self expectNodeBlockMethodForItemAtIndexPath:indexPath];
    }
  }

  [window layoutIfNeeded];

  // Assert item counts & content:
  [self assertCollectionNodeContent];
}

/**
 * Adds expectations for the sequence:
 *
 * numberOfSectionsInCollectionNode:
 * for section in countsArray
 *  numberOfItemsInSection:
 */
- (void)expectDataSourceCountMethods
{
  // -numberOfSectionsInCollectionNode
  OCMExpect([mockDataSource numberOfSectionsInCollectionNode:collectionNode])
  .andReturn(sections.count);
  
  // For each section:
  // Note: Skip fast enumeration for readability.
  for (NSInteger section = 0; section < sections.count; section++) {
    OCMExpect([mockDataSource collectionNode:collectionNode numberOfItemsInSection:section])
    .andReturn(sections[section].nodeModels.count);
  }
}

- (void)expectNodeModelMethodForItemAtIndexPath:(NSIndexPath *)indexPath nodeModel:(id)nodeModel
{
  OCMExpect([mockDataSource collectionNode:collectionNode nodeModelForItemAtIndexPath:indexPath])
  .andReturn(nodeModel);
}

- (void)expectContextMethodForSection:(NSInteger)section
{
  OCMExpect([mockDataSource collectionNode:collectionNode contextForSection:section])
  .andReturn(sections[section]);
}

- (void)expectNodeBlockMethodForItemAtIndexPath:(NSIndexPath *)indexPath
{
  OCMExpect([mockDataSource collectionNode:collectionNode nodeBlockForItemAtIndexPath:indexPath])
  .andReturn((A_SCellNodeBlock)^{
    A_SCellNode *node = [A_STestCellNode new];
    // Generating multiple partial mocks of the same class is not thread-safe.
    id mockNode;
    @synchronized (NSNull.null) {
      mockNode = OCMPartialMock(node);
    }
    [mockNode setExpectationOrderMatters:YES];
    return mockNode;
  });
}

/// Asserts that counts match and all view-models are up-to-date between us and collectionNode.
- (void)assertCollectionNodeContent
{
  // Assert section count
  XCTAssertEqual(collectionNode.numberOfSections, sections.count);

  for (NSInteger section = 0; section < sections.count; section++) {
    A_STestSection *sectionObject = sections[section];
    NSArray *nodeModels = sectionObject.nodeModels;

    // Assert section object
    XCTAssertEqualObjects([collectionNode contextForSection:section], sectionObject);
    
    // Assert item count
    XCTAssertEqual([collectionNode numberOfItemsInSection:section], nodeModels.count);
    for (NSInteger item = 0; item < nodeModels.count; item++) {
      // Assert node model
      // Could use pointer equality but the error message is less readable.
      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
      id nodeModel = nodeModels[indexPath.item];
      XCTAssertEqualObjects(nodeModel, [collectionNode nodeModelForItemAtIndexPath:indexPath]);
      A_SCellNode *node = [collectionNode nodeForItemAtIndexPath:indexPath];
      XCTAssertEqualObjects(node.nodeModel, nodeModel);
    }
  }
}

/**
 * Updates the collection node, with expectations and assertions about the call-order and the correctness of the
 * new data. You should update the data source _before_ calling this method.
 *
 * skippedReloadIndexPaths are the old index paths for nodes that should use -canUpdateToNodeModel: instead of being refetched.
 */
- (void)performUpdateReloadingSections:(NSDictionary<NSNumber *, id> *)reloadedSections
                        reloadingItems:(NSDictionary<NSIndexPath *, id> *)reloadedItems
                        reloadMappings:(NSDictionary<NSIndexPath *, NSIndexPath *> *)reloadMappings
                        insertingItems:(NSDictionary<NSIndexPath *, id> *)insertedItems
                         deletingItems:(NSArray<NSIndexPath *> *)deletedItems
               skippedReloadIndexPaths:(NSArray<NSIndexPath *> *)skippedReloadIndexPaths
{
  [collectionNode performBatchUpdates:^{
    // First update our data source.
    [reloadedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
      sections[key.section].nodeModels[key.item] = obj;
    }];
    [reloadedSections enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
      sections[key.integerValue] = obj;
    }];
    
    // Deletion paths, sorted descending
    for (NSIndexPath *indexPath in [deletedItems sortedArrayUsingSelector:@selector(compare:)].reverseObjectEnumerator) {
      [sections[indexPath.section].nodeModels removeObjectAtIndex:indexPath.item];
    }
    
    // Insertion paths, sorted ascending.
    NSArray *insertionsSortedAcending = [insertedItems.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSIndexPath *indexPath in insertionsSortedAcending) {
      [sections[indexPath.section].nodeModels insertObject:insertedItems[indexPath] atIndex:indexPath.item];
    }
    
    // Then update the collection node.
    NSMutableIndexSet *reloadedSectionIndexes = [NSMutableIndexSet indexSet];
    for (NSNumber *i in reloadedSections) {
      [reloadedSectionIndexes addIndex:i.integerValue];
    }
    [collectionNode reloadSections:reloadedSectionIndexes];
    [collectionNode reloadItemsAtIndexPaths:reloadedItems.allKeys];
    [collectionNode deleteItemsAtIndexPaths:deletedItems];
    [collectionNode insertItemsAtIndexPaths:insertedItems.allKeys];
    
    // Before the commit, lay out our expectations.
    
    // Expect it to load the new counts.
    [self expectDataSourceCountMethods];
    
    // Combine reloads + inserts and expect them to load content for all of them, in ascending order.
    NSMutableDictionary<NSIndexPath *, id> *insertsPlusReloads = [NSMutableDictionary dictionary];
    [insertsPlusReloads addEntriesFromDictionary:insertedItems];

    // Go through reloaded sections and add all their items into `insertsPlusReloads`
    [reloadedSectionIndexes enumerateIndexesUsingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
      [self expectContextMethodForSection:section];
      NSArray *nodeModels = sections[section].nodeModels;
      for (NSInteger i = 0; i < nodeModels.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:section];
        insertsPlusReloads[indexPath] = nodeModels[i];
      }
    }];

    [reloadedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
      insertsPlusReloads[reloadMappings[key]] = obj;
    }];
    
    for (NSIndexPath *indexPath in [insertsPlusReloads.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
      [self expectNodeModelMethodForItemAtIndexPath:indexPath nodeModel:insertsPlusReloads[indexPath]];
      NSIndexPath *oldIndexPath = [reloadMappings allKeysForObject:indexPath].firstObject;
      BOOL isSkippedReload = oldIndexPath && [skippedReloadIndexPaths containsObject:oldIndexPath];
      if (!isSkippedReload) {
        [self expectNodeBlockMethodForItemAtIndexPath:indexPath];
      }
    }
  } completion:nil];

  // Assert that the counts and node models are all correct now.
  [self assertCollectionNodeContent];
}

@end

#pragma mark - Other Objects

@implementation A_STestCellNode

- (BOOL)canUpdateToNodeModel:(id)nodeModel
{
  // Our tests default to NO for migrating node models. We use OCMExpect to return YES when we specifically want to.
  return NO;
}

@end

@implementation A_STestSection
@synthesize collectionView;
@synthesize sectionName;

- (instancetype)init
{
  if (self = [super init]) {
    _nodeModels = [NSMutableArray array];
  }
  return self;
}

@end