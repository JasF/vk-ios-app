//
//  A_SLayoutFlatteningTests.m
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
#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SLayoutSpec.h>

@interface A_SLayoutFlatteningTests : XCTestCase
@end

@implementation A_SLayoutFlatteningTests

static A_SLayout *layoutWithCustomPosition(CGPoint position, id<A_SLayoutElement> element, NSArray<A_SLayout *> *sublayouts)
{
  return [A_SLayout layoutWithLayoutElement:element
                                      size:CGSizeMake(100, 100)
                                  position:position
                                sublayouts:sublayouts];
}

static A_SLayout *layout(id<A_SLayoutElement> element, NSArray<A_SLayout *> *sublayouts)
{
  return layoutWithCustomPosition(CGPointZero, element, sublayouts);
}

- (void)testThatFlattenedLayoutContainsOnlyDirectSubnodesInValidOrder
{
  A_SLayout *flattenedLayout;
  
  @autoreleasepool {
    NSMutableArray<A_SDisplayNode *> *subnodes = [NSMutableArray array];
    NSMutableArray<A_SLayoutSpec *> *layoutSpecs = [NSMutableArray array];
    NSMutableArray<A_SDisplayNode *> *indirectSubnodes = [NSMutableArray array];
    
    A_SDisplayNode *(^subnode)() = ^A_SDisplayNode *() { [subnodes addObject:[[A_SDisplayNode alloc] init]]; return [subnodes lastObject]; };
    A_SLayoutSpec *(^layoutSpec)() = ^A_SLayoutSpec *() { [layoutSpecs addObject:[[A_SLayoutSpec alloc] init]]; return [layoutSpecs lastObject]; };
    A_SDisplayNode *(^indirectSubnode)() = ^A_SDisplayNode *() { [indirectSubnodes addObject:[[A_SDisplayNode alloc] init]]; return [indirectSubnodes lastObject]; };
    
    NSArray<A_SLayout *> *sublayouts = @[
                                        layout(subnode(), @[
                                                            layout(indirectSubnode(), @[]),
                                                            ]),
                                        layout(layoutSpec(), @[
                                                               layout(subnode(), @[]),
                                                               layout(layoutSpec(), @[
                                                                                      layout(layoutSpec(), @[]),
                                                                                      layout(subnode(), @[]),
                                                                                      ]),
                                                               layout(layoutSpec(), @[]),
                                                               ]),
                                        layout(layoutSpec(), @[
                                                               layout(subnode(), @[
                                                                                   layout(indirectSubnode(), @[]),
                                                                                   layout(indirectSubnode(), @[
                                                                                                               layout(indirectSubnode(), @[])
                                                                                                               ]),
                                                                                   ])
                                                               ]),
                                        layout(subnode(), @[]),
                                        ];
    
    A_SDisplayNode *rootNode = [[A_SDisplayNode alloc] init];
    A_SLayout *originalLayout = [A_SLayout layoutWithLayoutElement:rootNode
                                                            size:CGSizeMake(1000, 1000)
                                                      sublayouts:sublayouts];
    flattenedLayout = [originalLayout filteredNodeLayoutTree];
    NSArray<A_SLayout *> *flattenedSublayouts = flattenedLayout.sublayouts;
    NSUInteger sublayoutsCount = flattenedSublayouts.count;
    
    XCTAssertEqualObjects(originalLayout.layoutElement, flattenedLayout.layoutElement, @"The root node should be reserved");
    XCTAssertTrue(A_SPointIsNull(flattenedLayout.position), @"Position of the root layout should be null");
    XCTAssertEqual(subnodes.count, sublayoutsCount, @"Flattened layout should only contain direct subnodes");
    for (int i = 0; i < sublayoutsCount; i++) {
      XCTAssertEqualObjects(subnodes[i], flattenedSublayouts[i].layoutElement, @"Sublayouts should be in correct order (flattened in DFS fashion)");
    }
  }
  
  for (A_SLayout *sublayout in flattenedLayout.sublayouts) {
    XCTAssertNotNil(sublayout.layoutElement, @"Sublayout elements should be retained");
    XCTAssertEqual(0, sublayout.sublayouts.count, @"Sublayouts should not have their own sublayouts");
  }
}

#pragma mark - Test reusing A_SLayouts while flattening

- (void)testThatLayoutWithNonNullPositionIsNotReused
{
  A_SDisplayNode *rootNode = [[A_SDisplayNode alloc] init];
  A_SLayout *originalLayout = layoutWithCustomPosition(CGPointMake(10, 10), rootNode, @[]);
  A_SLayout *flattenedLayout = [originalLayout filteredNodeLayoutTree];
  XCTAssertNotEqualObjects(originalLayout, flattenedLayout, "@Layout should be reused");
  XCTAssertTrue(A_SPointIsNull(flattenedLayout.position), @"Position of a root layout should be null");
}

- (void)testThatLayoutWithNullPositionAndNoSublayoutIsReused
{
  A_SDisplayNode *rootNode = [[A_SDisplayNode alloc] init];
  A_SLayout *originalLayout = layoutWithCustomPosition(A_SPointNull, rootNode, @[]);
  A_SLayout *flattenedLayout = [originalLayout filteredNodeLayoutTree];
  XCTAssertEqualObjects(originalLayout, flattenedLayout, "@Layout should be reused");
  XCTAssertTrue(A_SPointIsNull(flattenedLayout.position), @"Position of a root layout should be null");
}

- (void)testThatLayoutWithNullPositionAndFlattenedNodeSublayoutsIsReused
{
  A_SLayout *flattenedLayout;
  
  @autoreleasepool {
    A_SDisplayNode *rootNode = [[A_SDisplayNode alloc] init];
    NSMutableArray<A_SDisplayNode *> *subnodes = [NSMutableArray array];
    A_SDisplayNode *(^subnode)() = ^A_SDisplayNode *() { [subnodes addObject:[[A_SDisplayNode alloc] init]]; return [subnodes lastObject]; };
    A_SLayout *originalLayout = layoutWithCustomPosition(A_SPointNull,
                                                        rootNode,
                                                        @[
                                                          layoutWithCustomPosition(CGPointMake(10, 10), subnode(), @[]),
                                                          layoutWithCustomPosition(CGPointMake(20, 20), subnode(), @[]),
                                                          layoutWithCustomPosition(CGPointMake(30, 30), subnode(), @[]),
                                                          ]);
    flattenedLayout = [originalLayout filteredNodeLayoutTree];
    XCTAssertEqualObjects(originalLayout, flattenedLayout, "@Layout should be reused");
    XCTAssertTrue(A_SPointIsNull(flattenedLayout.position), @"Position of the root layout should be null");
  }
  
  for (A_SLayout *sublayout in flattenedLayout.sublayouts) {
    XCTAssertNotNil(sublayout.layoutElement, @"Sublayout elements should be retained");
    XCTAssertEqual(0, sublayout.sublayouts.count, @"Sublayouts should not have their own sublayouts");
  }
}

- (void)testThatLayoutWithNullPositionAndUnflattenedSublayoutsIsNotReused
{
  A_SLayout *flattenedLayout;
  
  @autoreleasepool {
    A_SDisplayNode *rootNode = [[A_SDisplayNode alloc] init];
    NSMutableArray<A_SDisplayNode *> *subnodes = [NSMutableArray array];
    NSMutableArray<A_SLayoutSpec *> *layoutSpecs = [NSMutableArray array];
    NSMutableArray<A_SDisplayNode *> *indirectSubnodes = [NSMutableArray array];
    NSMutableArray<A_SLayout *> *reusedLayouts = [NSMutableArray array];
    
    A_SDisplayNode *(^subnode)() = ^A_SDisplayNode *() { [subnodes addObject:[[A_SDisplayNode alloc] init]]; return [subnodes lastObject]; };
    A_SLayoutSpec *(^layoutSpec)() = ^A_SLayoutSpec *() { [layoutSpecs addObject:[[A_SLayoutSpec alloc] init]]; return [layoutSpecs lastObject]; };
    A_SDisplayNode *(^indirectSubnode)() = ^A_SDisplayNode *() { [indirectSubnodes addObject:[[A_SDisplayNode alloc] init]]; return [indirectSubnodes lastObject]; };
    A_SLayout *(^reusedLayout)(A_SDisplayNode *) = ^A_SLayout *(A_SDisplayNode *subnode) { [reusedLayouts addObject:layout(subnode, @[])]; return [reusedLayouts lastObject]; };
    
    /*
     * Layouts with sublayouts of both nodes and layout specs should not be reused.
     * However, all flattened node sublayouts with valid position should be reused.
     */
    A_SLayout *originalLayout = layoutWithCustomPosition(A_SPointNull,
                                                        rootNode,
                                                        @[
                                                          reusedLayout(subnode()),
                                                          // The 2 node sublayouts below should be reused although they are in a layout spec sublayout.
                                                          // That is because each of them have an absolute position of zero.
                                                          // This case can happen, for example, as the result of a background/overlay layout spec.
                                                          layout(layoutSpec(), @[
                                                                                 reusedLayout(subnode()),
                                                                                 reusedLayout(subnode())
                                                                                 ]),
                                                          layout(subnode(), @[
                                                                              layout(layoutSpec(), @[])
                                                                              ]),
                                                          layout(subnode(), @[
                                                                              layout(indirectSubnode(), @[])
                                                                              ]),
                                                          layoutWithCustomPosition(CGPointMake(10, 10), subnode(), @[]),
                                                          // The 2 node sublayouts below shouldn't be reused because they have non-zero absolute positions.
                                                          layoutWithCustomPosition(CGPointMake(20, 20), layoutSpec(), @[
                                                                                                                        layout(subnode(), @[]),
                                                                                                                        layout(subnode(), @[])
                                                                                                                        ]),
                                                          ]);
    flattenedLayout = [originalLayout filteredNodeLayoutTree];
    NSArray<A_SLayout *> *flattenedSublayouts = flattenedLayout.sublayouts;
    NSUInteger sublayoutsCount = flattenedSublayouts.count;
    
    XCTAssertNotEqualObjects(originalLayout, flattenedLayout, @"Original layout should not be reused");
    XCTAssertEqualObjects(originalLayout.layoutElement, flattenedLayout.layoutElement, @"The root node should be reserved");
    XCTAssertTrue(A_SPointIsNull(flattenedLayout.position), @"Position of the root layout should be null");
    XCTAssertTrue(reusedLayouts.count <= sublayoutsCount, @"Some sublayouts can't be reused");
    XCTAssertEqual(subnodes.count, sublayoutsCount, @"Flattened layout should only contain direct subnodes");
    int numOfActualReusedLayouts = 0;
    for (int i = 0; i < sublayoutsCount; i++) {
      A_SLayout *sublayout = flattenedSublayouts[i];
      XCTAssertEqualObjects(subnodes[i], sublayout.layoutElement, @"Sublayouts should be in correct order (flattened in DFS fashion)");
      if ([reusedLayouts containsObject:sublayout]) {
        numOfActualReusedLayouts++;
      }
    }
    XCTAssertEqual(numOfActualReusedLayouts, reusedLayouts.count, @"Should reuse all layouts that can be reused");
  }
  
  for (A_SLayout *sublayout in flattenedLayout.sublayouts) {
    XCTAssertNotNil(sublayout.layoutElement, @"Sublayout elements should be retained");
    XCTAssertEqual(0, sublayout.sublayouts.count, @"Sublayouts should not have their own sublayouts");
  }
}

@end
