//
//  A_SCollectionViewFlowLayoutInspectorTests.m
//  Tex_ture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /A_SDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <OCMock/OCMock.h>
#import "A_SXCTExtensions.h"

#import <Async_DisplayKit/A_SCollectionView.h>
#import <Async_DisplayKit/A_SCollectionNode.h>
#import <Async_DisplayKit/A_SCollectionViewFlowLayoutInspector.h>
#import <Async_DisplayKit/A_SCellNode.h>
#import <Async_DisplayKit/A_SCollectionView+Undeprecated.h>

@interface A_SCollectionView (Private)

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout;

@end

/**
 * Test Data Source
 */
@interface InspectorTestDataSource : NSObject <A_SCollectionDataSource>
@end

@implementation InspectorTestDataSource

- (A_SCellNode *)collectionView:(A_SCollectionView *)collectionView nodeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [[A_SCellNode alloc] init];
}

- (A_SCellNodeBlock)collectionView:(A_SCollectionView *)collectionView nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return ^{ return [[A_SCellNode alloc] init]; };
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return 0;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return 2;
}

@end

@protocol InspectorTestDataSourceDelegateProtocol <A_SCollectionDataSource, A_SCollectionDelegate>

@end

@interface InspectorTestDataSourceDelegateWithoutNodeConstrainedSize : NSObject <InspectorTestDataSourceDelegateProtocol>
@end

@implementation InspectorTestDataSourceDelegateWithoutNodeConstrainedSize

- (A_SCellNodeBlock)collectionView:(A_SCollectionView *)collectionView nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return ^{ return [[A_SCellNode alloc] init]; };
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return 0;
}

@end

@interface A_SCollectionViewFlowLayoutInspectorTests : XCTestCase

@end

/**
 * Test Delegate for Header Reference Size Implementation
 */
@interface HeaderReferenceSizeTestDelegate : NSObject <A_SCollectionDelegateFlowLayout>

@end

@implementation HeaderReferenceSizeTestDelegate

- (CGSize)collectionView:(A_SCollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
  return CGSizeMake(125.0, 125.0);
}

@end

/**
 * Test Delegate for Footer Reference Size Implementation
 */
@interface FooterReferenceSizeTestDelegate : NSObject <A_SCollectionDelegateFlowLayout>

@end

@implementation FooterReferenceSizeTestDelegate

- (CGSize)collectionView:(A_SCollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
  return CGSizeMake(125.0, 125.0);
}

@end

@implementation A_SCollectionViewFlowLayoutInspectorTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - #collectionView:constrainedSizeForSupplementaryNodeOfKind:atIndexPath:

// Vertical

// Delegate implementation

- (void)testThatItReturnsAVerticalConstrainedSizeFromTheHeaderDelegateImplementation
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  HeaderReferenceSizeTestDelegate *delegate = [[HeaderReferenceSizeTestDelegate alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionVertical;

  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  A_SCollectionView *collectionView = [[A_SCollectionView alloc] initWithFrame:rect collectionViewLayout:layout];
  collectionView.asyncDataSource = dataSource;
  collectionView.asyncDelegate = delegate;
  
  A_SCollectionViewFlowLayoutInspector *inspector = A_SDynamicCast(collectionView.layoutInspector, A_SCollectionViewFlowLayoutInspector);
  A_SSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  A_SSizeRange sizeCompare = A_SSizeRangeMake(CGSizeMake(collectionView.bounds.size.width, 125.0));

  A_SXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the values returned in the delegate implementation");
  
  collectionView.asyncDataSource = nil;
  collectionView.asyncDelegate = nil;
}

- (void)testThatItReturnsAVerticalConstrainedSizeFromTheFooterDelegateImplementation
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  FooterReferenceSizeTestDelegate *delegate = [[FooterReferenceSizeTestDelegate alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionVertical;
  
  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  A_SCollectionView *collectionView = [[A_SCollectionView alloc] initWithFrame:rect collectionViewLayout:layout];
  collectionView.asyncDataSource = dataSource;
  collectionView.asyncDelegate = delegate;
  
  A_SCollectionViewFlowLayoutInspector *inspector = A_SDynamicCast(collectionView.layoutInspector, A_SCollectionViewFlowLayoutInspector);
  A_SSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  A_SSizeRange sizeCompare = A_SSizeRangeMake(CGSizeMake(collectionView.bounds.size.width, 125.0));
  A_SXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the values returned in the delegate implementation");
  
  collectionView.asyncDataSource = nil;
  collectionView.asyncDelegate = nil;
}

// Size implementation

- (void)testThatItReturnsAVerticalConstrainedSizeFromTheHeaderProperty
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionVertical;
  layout.headerReferenceSize = CGSizeMake(125.0, 125.0);
  
  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  A_SCollectionView *collectionView = [[A_SCollectionView alloc] initWithFrame:rect collectionViewLayout:layout];
  collectionView.asyncDataSource = dataSource;
  
  A_SCollectionViewFlowLayoutInspector *inspector = A_SDynamicCast(collectionView.layoutInspector, A_SCollectionViewFlowLayoutInspector);
  A_SSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  A_SSizeRange sizeCompare = A_SSizeRangeMake(CGSizeMake(collectionView.bounds.size.width, 125.0));
  A_SXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the size set on the layout");
  
  collectionView.asyncDataSource = nil;
  collectionView.asyncDelegate = nil;
}

- (void)testThatItReturnsAVerticalConstrainedSizeFromTheFooterProperty
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionVertical;
  layout.footerReferenceSize = CGSizeMake(125.0, 125.0);
  
  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  A_SCollectionView *collectionView = [[A_SCollectionView alloc] initWithFrame:rect collectionViewLayout:layout];
  collectionView.asyncDataSource = dataSource;
  
  A_SCollectionViewFlowLayoutInspector *inspector = A_SDynamicCast(collectionView.layoutInspector, A_SCollectionViewFlowLayoutInspector);
  A_SSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  A_SSizeRange sizeCompare = A_SSizeRangeMake(CGSizeMake(collectionView.bounds.size.width, 125.0));
  A_SXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the size set on the layout");
  
  collectionView.asyncDataSource = nil;
  collectionView.asyncDelegate = nil;
}

// Horizontal

- (void)testThatItReturnsAHorizontalConstrainedSizeFromTheHeaderDelegateImplementation
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  HeaderReferenceSizeTestDelegate *delegate = [[HeaderReferenceSizeTestDelegate alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  
  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  A_SCollectionView *collectionView = [[A_SCollectionView alloc] initWithFrame:rect collectionViewLayout:layout];
  collectionView.asyncDataSource = dataSource;
  collectionView.asyncDelegate = delegate;
  
  A_SCollectionViewFlowLayoutInspector *inspector = A_SDynamicCast(collectionView.layoutInspector, A_SCollectionViewFlowLayoutInspector);
  A_SSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  A_SSizeRange sizeCompare = A_SSizeRangeMake(CGSizeMake(125.0, collectionView.bounds.size.height));
  A_SXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the values returned in the delegate implementation");
  
  collectionView.asyncDataSource = nil;
  collectionView.asyncDelegate = nil;
}

- (void)testThatItReturnsAHorizontalConstrainedSizeFromTheFooterDelegateImplementation
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  FooterReferenceSizeTestDelegate *delegate = [[FooterReferenceSizeTestDelegate alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  
  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  A_SCollectionView *collectionView = [[A_SCollectionView alloc] initWithFrame:rect collectionViewLayout:layout];
  collectionView.asyncDataSource = dataSource;
  collectionView.asyncDelegate = delegate;
  
  A_SCollectionViewFlowLayoutInspector *inspector = A_SDynamicCast(collectionView.layoutInspector, A_SCollectionViewFlowLayoutInspector);
  A_SSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  A_SSizeRange sizeCompare = A_SSizeRangeMake(CGSizeMake(125.0, collectionView.bounds.size.height));
  A_SXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the values returned in the delegate implementation");
  
  collectionView.asyncDataSource = nil;
  collectionView.asyncDelegate = nil;
}

// Size implementation

- (void)testThatItReturnsAHorizontalConstrainedSizeFromTheHeaderProperty
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  layout.headerReferenceSize = CGSizeMake(125.0, 125.0);
  
  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  A_SCollectionView *collectionView = [[A_SCollectionView alloc] initWithFrame:rect collectionViewLayout:layout];
  collectionView.asyncDataSource = dataSource;
  
  A_SCollectionViewFlowLayoutInspector *inspector = A_SDynamicCast(collectionView.layoutInspector, A_SCollectionViewFlowLayoutInspector);
  A_SSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  A_SSizeRange sizeCompare = A_SSizeRangeMake(CGSizeMake(125.0, collectionView.bounds.size.width));
  A_SXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the size set on the layout");
  
  collectionView.asyncDataSource = nil;
  collectionView.asyncDelegate = nil;
}

- (void)testThatItReturnsAHorizontalConstrainedSizeFromTheFooterProperty
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  layout.footerReferenceSize = CGSizeMake(125.0, 125.0);
  
  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  A_SCollectionView *collectionView = [[A_SCollectionView alloc] initWithFrame:rect collectionViewLayout:layout];
  collectionView.asyncDataSource = dataSource;
  
  A_SCollectionViewFlowLayoutInspector *inspector = A_SDynamicCast(collectionView.layoutInspector, A_SCollectionViewFlowLayoutInspector);
  A_SSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  A_SSizeRange sizeCompare = A_SSizeRangeMake(CGSizeMake(125.0, collectionView.bounds.size.height));
  A_SXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the size set on the layout");
  
  collectionView.asyncDataSource = nil;
  collectionView.asyncDelegate = nil;
}

- (void)testThatItReturnsZeroSizeWhenNoReferenceSizeIsImplemented
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  HeaderReferenceSizeTestDelegate *delegate = [[HeaderReferenceSizeTestDelegate alloc] init];
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  A_SCollectionView *collectionView = [[A_SCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  collectionView.asyncDataSource = dataSource;
  collectionView.asyncDelegate = delegate;
  A_SCollectionViewFlowLayoutInspector *inspector = A_SDynamicCast(collectionView.layoutInspector, A_SCollectionViewFlowLayoutInspector);
  A_SSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  A_SSizeRange sizeCompare = A_SSizeRangeMake(CGSizeZero, CGSizeZero);
  XCTAssert(CGSizeEqualToSize(size.min, sizeCompare.min) && CGSizeEqualToSize(size.max, sizeCompare.max), @"should have a zero size");
  
  collectionView.asyncDataSource = nil;
  collectionView.asyncDelegate = nil;
}

#pragma mark - #collectionView:supplementaryNodesOfKind:inSection:

- (void)testThatItReturnsOneWhenAValidSizeIsImplementedOnTheDelegate
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  HeaderReferenceSizeTestDelegate *delegate = [[HeaderReferenceSizeTestDelegate alloc] init];
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  A_SCollectionView *collectionView = [[A_SCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  collectionView.asyncDataSource = dataSource;
  collectionView.asyncDelegate = delegate;
  A_SCollectionViewFlowLayoutInspector *inspector = A_SDynamicCast(collectionView.layoutInspector, A_SCollectionViewFlowLayoutInspector);
  NSUInteger count = [inspector collectionView:collectionView supplementaryNodesOfKind:UICollectionElementKindSectionHeader inSection:0];
  XCTAssert(count == 1, @"should have a header supplementary view");
  
  collectionView.asyncDataSource = nil;
  collectionView.asyncDelegate = nil;
}

- (void)testThatItReturnsOneWhenAValidSizeIsImplementedOnTheLayout
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  HeaderReferenceSizeTestDelegate *delegate = [[HeaderReferenceSizeTestDelegate alloc] init];
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.footerReferenceSize = CGSizeMake(125.0, 125.0);
  A_SCollectionView *collectionView = [[A_SCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  collectionView.asyncDataSource = dataSource;
  collectionView.asyncDelegate = delegate;
  A_SCollectionViewFlowLayoutInspector *inspector = A_SDynamicCast(collectionView.layoutInspector, A_SCollectionViewFlowLayoutInspector);
  NSUInteger count = [inspector collectionView:collectionView supplementaryNodesOfKind:UICollectionElementKindSectionFooter inSection:0];
  XCTAssert(count == 1, @"should have a footer supplementary view");
  
  collectionView.asyncDataSource = nil;
  collectionView.asyncDelegate = nil;
}

- (void)testThatItReturnsNoneWhenNoReferenceSizeIsImplemented
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  HeaderReferenceSizeTestDelegate *delegate = [[HeaderReferenceSizeTestDelegate alloc] init];
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  A_SCollectionView *collectionView = [[A_SCollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  collectionView.asyncDataSource = dataSource;
  collectionView.asyncDelegate = delegate;
  A_SCollectionViewFlowLayoutInspector *inspector = A_SDynamicCast(collectionView.layoutInspector, A_SCollectionViewFlowLayoutInspector);
  NSUInteger count = [inspector collectionView:collectionView supplementaryNodesOfKind:UICollectionElementKindSectionFooter inSection:0];
  XCTAssert(count == 0, @"should not have a footer supplementary view");
  
  collectionView.asyncDataSource = nil;
  collectionView.asyncDelegate = nil;
}

- (void)testThatItThrowsIfNodeConstrainedSizeIsImplementedOnDataSourceButNotOnDelegateLayoutInspector
{
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  A_SCollectionNode *node = [[A_SCollectionNode alloc] initWithCollectionViewLayout:layout];
  A_SCollectionView *collectionView = node.view;
  
  id dataSourceAndDelegate = [OCMockObject mockForProtocol:@protocol(InspectorTestDataSourceDelegateProtocol)];
  A_SSizeRange constrainedSize = A_SSizeRangeMake(CGSizeZero, CGSizeZero);
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
  NSValue *value = [NSValue value:&constrainedSize withObjCType:@encode(A_SSizeRange)];
  [[[dataSourceAndDelegate stub] andReturnValue:value] collectionNode:node constrainedSizeForItemAtIndexPath:indexPath];
  node.dataSource = dataSourceAndDelegate;
  
  id delegate = [InspectorTestDataSourceDelegateWithoutNodeConstrainedSize new];
  node.delegate = delegate;
  
  A_SCollectionViewLayoutInspector *inspector = [[A_SCollectionViewLayoutInspector alloc] init];
  
  collectionView.layoutInspector = inspector;
  XCTAssertThrows([inspector collectionView:collectionView constrainedSizeForNodeAtIndexPath:indexPath]);
  
  node.delegate = dataSourceAndDelegate;
  XCTAssertNoThrow([inspector collectionView:collectionView constrainedSizeForNodeAtIndexPath:indexPath]);
}

- (void)testThatItThrowsIfNodeConstrainedSizeIsImplementedOnDataSourceButNotOnDelegateFlowLayoutInspector
{
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  
  A_SCollectionNode *node = [[A_SCollectionNode alloc] initWithCollectionViewLayout:layout];
  A_SCollectionView *collectionView = node.view;
  id dataSourceAndDelegate = [OCMockObject mockForProtocol:@protocol(InspectorTestDataSourceDelegateProtocol)];
  A_SSizeRange constrainedSize = A_SSizeRangeMake(CGSizeZero, CGSizeZero);
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
  NSValue *value = [NSValue value:&constrainedSize withObjCType:@encode(A_SSizeRange)];
  
  [[[dataSourceAndDelegate stub] andReturnValue:value] collectionNode:node constrainedSizeForItemAtIndexPath:indexPath];
  node.dataSource = dataSourceAndDelegate;
  id delegate = [InspectorTestDataSourceDelegateWithoutNodeConstrainedSize new];
  
  node.delegate = delegate;
  A_SCollectionViewFlowLayoutInspector *inspector = collectionView.layoutInspector;

  XCTAssertThrows([inspector collectionView:collectionView constrainedSizeForNodeAtIndexPath:indexPath]);
  
  node.delegate = dataSourceAndDelegate;
  XCTAssertNoThrow([inspector collectionView:collectionView constrainedSizeForNodeAtIndexPath:indexPath]);
}

@end
