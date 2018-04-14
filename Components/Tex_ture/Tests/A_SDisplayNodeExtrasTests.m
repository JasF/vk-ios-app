//
//  A_SDisplayNodeExtrasTests.m
//  Tex_ture
//
//  Created by Kiel Gillard on 27/06/2016.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Async_DisplayKit/Async_DisplayKit.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>

@interface A_SDisplayNodeExtrasTests : XCTestCase

@end

@interface TestDisplayNode : A_SDisplayNode
@end

@implementation TestDisplayNode
@end

@implementation A_SDisplayNodeExtrasTests

- (void)testShallowFindSubnodesOfSubclass {
  A_SDisplayNode *supernode = [[A_SDisplayNode alloc] initWithLayerBlock:^CALayer * _Nonnull{
    return [CALayer layer];
  }];
  NSUInteger count = 10;
  NSMutableArray *expected = [[NSMutableArray alloc] initWithCapacity:count];
  for (NSUInteger nodeIndex = 0; nodeIndex < count; nodeIndex++) {
    TestDisplayNode *node = [[TestDisplayNode alloc] initWithLayerBlock:^CALayer * _Nonnull{
      return [CALayer layer];
    }];
    [supernode addSubnode:node];
    [expected addObject:node];
  }
  NSArray *found = A_SDisplayNodeFindAllSubnodesOfClass(supernode, [TestDisplayNode class]);
  XCTAssertEqualObjects(found, expected, @"Expecting %lu %@ nodes, found %lu", (unsigned long)count, [TestDisplayNode class], (unsigned long)found.count);
}

- (void)testDeepFindSubnodesOfSubclass {
  A_SDisplayNode *supernode = [[A_SDisplayNode alloc] initWithLayerBlock:^CALayer * _Nonnull{
    return [CALayer layer];
  }];
  
  const NSUInteger count = 2;
  const NSUInteger levels = 2;
  const NSUInteger capacity = [[self class] capacityForCount:count levels:levels];
  NSMutableArray *expected = [[NSMutableArray alloc] initWithCapacity:capacity];
  
  [[self class] addSubnodesToNode:supernode number:count remainingLevels:levels accumulated:expected];
  
  NSArray *found = A_SDisplayNodeFindAllSubnodesOfClass(supernode, [TestDisplayNode class]);
  XCTAssertEqualObjects(found, expected, @"Expecting %lu %@ nodes, found %lu", (unsigned long)count, [TestDisplayNode class], (unsigned long)found.count);
}

+ (void)addSubnodesToNode:(A_SDisplayNode *)supernode number:(NSUInteger)number remainingLevels:(NSUInteger)level accumulated:(inout NSMutableArray *)expected {
  if (level == 0) return;
  for (NSUInteger nodeIndex = 0; nodeIndex < number; nodeIndex++) {
    TestDisplayNode *node = [[TestDisplayNode alloc] initWithLayerBlock:^CALayer * _Nonnull{
      return [CALayer layer];
    }];
    [supernode addSubnode:node];
    [expected addObject:node];
    [self addSubnodesToNode:node number:number remainingLevels:(level - 1) accumulated:expected];
  }
}

// Graph theory is failing me atm.
+ (NSUInteger)capacityForCount:(NSUInteger)count levels:(NSUInteger)level {
  if (level == 0) return 0;
  return pow(count, level) + [self capacityForCount:count levels:(level - 1)];
}

@end
