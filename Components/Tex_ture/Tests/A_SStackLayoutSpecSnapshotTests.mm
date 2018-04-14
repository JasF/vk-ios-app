//
//  A_SStackLayoutSpecSnapshotTests.mm
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

#import "A_SLayoutSpecSnapshotTestsHelper.h"

#import <Async_DisplayKit/A_SStackLayoutSpec.h>
#import <Async_DisplayKit/A_SStackLayoutSpecUtilities.h>
#import <Async_DisplayKit/A_SBackgroundLayoutSpec.h>
#import <Async_DisplayKit/A_SRatioLayoutSpec.h>
#import <Async_DisplayKit/A_SInsetLayoutSpec.h>
#import <Async_DisplayKit/A_STextNode.h>

@interface A_SStackLayoutSpecSnapshotTests : A_SLayoutSpecSnapshotTestCase
@end

@implementation A_SStackLayoutSpecSnapshotTests

#pragma mark - Utility methods

static NSArray<A_SDisplayNode *> *defaultSubnodes()
{
  return defaultSubnodesWithSameSize(CGSizeZero, 0);
}

static NSArray<A_SDisplayNode *> *defaultSubnodesWithSameSize(CGSize subnodeSize, CGFloat flex)
{
  NSArray<A_SDisplayNode *> *subnodes = @[
    A_SDisplayNodeWithBackgroundColor([UIColor redColor], subnodeSize),
    A_SDisplayNodeWithBackgroundColor([UIColor blueColor], subnodeSize),
    A_SDisplayNodeWithBackgroundColor([UIColor greenColor], subnodeSize)
  ];
  for (A_SDisplayNode *subnode in subnodes) {
    subnode.style.flexGrow = flex;
    subnode.style.flexShrink = flex;
  }
  return subnodes;
}

static void setCGSizeToNode(CGSize size, A_SDisplayNode *node)
{
  node.style.width = A_SDimensionMakeWithPoints(size.width);
  node.style.height = A_SDimensionMakeWithPoints(size.height);
}

static NSArray<A_STextNode*> *defaultTextNodes()
{
  A_STextNode *textNode1 = [[A_STextNode alloc] init];
  textNode1.attributedText = [[NSAttributedString alloc] initWithString:@"Hello"
                                                             attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:20]}];
  textNode1.backgroundColor = [UIColor redColor];
  textNode1.layerBacked = YES;
  
  A_STextNode *textNode2 = [[A_STextNode alloc] init];
  textNode2.attributedText = [[NSAttributedString alloc] initWithString:@"Why, hello there! How are you?"
                                                             attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12]}];
  textNode2.backgroundColor = [UIColor blueColor];
  textNode2.layerBacked = YES;
  
  return @[textNode1, textNode2];
}

- (void)testStackLayoutSpecWithJustify:(A_SStackLayoutJustifyContent)justify
                            flexFactor:(CGFloat)flex
                             sizeRange:(A_SSizeRange)sizeRange
                            identifier:(NSString *)identifier
{
  A_SStackLayoutSpecStyle style = {
    .direction = A_SStackLayoutDirectionHorizontal,
    .justifyContent = justify
  };
  
  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize({50, 50}, flex);
  
  [self testStackLayoutSpecWithStyle:style sizeRange:sizeRange subnodes:subnodes identifier:identifier];
}

- (void)testStackLayoutSpecWithStyle:(A_SStackLayoutSpecStyle)style
                           sizeRange:(A_SSizeRange)sizeRange
                            subnodes:(NSArray *)subnodes
                          identifier:(NSString *)identifier
{
  [self testStackLayoutSpecWithStyle:style children:subnodes sizeRange:sizeRange subnodes:subnodes identifier:identifier];
}

- (void)testStackLayoutSpecWithStyle:(A_SStackLayoutSpecStyle)style
                            children:(NSArray *)children
                           sizeRange:(A_SSizeRange)sizeRange
                            subnodes:(NSArray *)subnodes
                          identifier:(NSString *)identifier
{
  A_SStackLayoutSpec *stackLayoutSpec =
  [A_SStackLayoutSpec
   stackLayoutSpecWithDirection:style.direction
   spacing:style.spacing
   justifyContent:style.justifyContent
   alignItems:style.alignItems
   flexWrap:style.flexWrap
   alignContent:style.alignContent
   lineSpacing:style.lineSpacing
   children:children];

  [self testStackLayoutSpec:stackLayoutSpec sizeRange:sizeRange subnodes:subnodes identifier:identifier];
}

- (void)testStackLayoutSpecWithDirection:(A_SStackLayoutDirection)direction
                itemsHorizontalAlignment:(A_SHorizontalAlignment)horizontalAlignment
                  itemsVerticalAlignment:(A_SVerticalAlignment)verticalAlignment
                              identifier:(NSString *)identifier
{
  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize({50, 50}, 0);
  
  A_SStackLayoutSpec *stackLayoutSpec = [[A_SStackLayoutSpec alloc] init];
  stackLayoutSpec.direction = direction;
  stackLayoutSpec.children = subnodes;
  stackLayoutSpec.horizontalAlignment = horizontalAlignment;
  stackLayoutSpec.verticalAlignment = verticalAlignment;
  
  CGSize exactSize = CGSizeMake(200, 200);
  static A_SSizeRange kSize = A_SSizeRangeMake(exactSize, exactSize);
  [self testStackLayoutSpec:stackLayoutSpec sizeRange:kSize subnodes:subnodes identifier:identifier];
}

- (void)testStackLayoutSpecWithBaselineAlignment:(A_SStackLayoutAlignItems)baselineAlignment
                                      identifier:(NSString *)identifier
{
  NSAssert(baselineAlignment == A_SStackLayoutAlignItemsBaselineFirst || baselineAlignment == A_SStackLayoutAlignItemsBaselineLast, @"Unexpected baseline alignment");
  NSArray<A_STextNode *> *textNodes = defaultTextNodes();
  textNodes[1].style.flexShrink = 1.0;
  
  A_SStackLayoutSpec *stackLayoutSpec = [A_SStackLayoutSpec horizontalStackLayoutSpec];
  stackLayoutSpec.children = textNodes;
  stackLayoutSpec.alignItems = baselineAlignment;
  
  static A_SSizeRange kSize = A_SSizeRangeMake(CGSizeMake(150, 0), CGSizeMake(150, CGFLOAT_MAX));
  [self testStackLayoutSpec:stackLayoutSpec sizeRange:kSize subnodes:textNodes identifier:identifier];
}

- (void)testStackLayoutSpec:(A_SStackLayoutSpec *)stackLayoutSpec
                  sizeRange:(A_SSizeRange)sizeRange
                   subnodes:(NSArray *)subnodes
                 identifier:(NSString *)identifier
{
  A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor whiteColor]);
  A_SLayoutSpec *layoutSpec = [A_SBackgroundLayoutSpec backgroundLayoutSpecWithChild:stackLayoutSpec background:backgroundNode];
  
  NSMutableArray *newSubnodes = [NSMutableArray arrayWithObject:backgroundNode];
  [newSubnodes addObjectsFromArray:subnodes];
  
  [self testLayoutSpec:layoutSpec sizeRange:sizeRange subnodes:newSubnodes identifier:identifier];
}

- (void)testStackLayoutSpecWithAlignContent:(A_SStackLayoutAlignContent)alignContent
                                lineSpacing:(CGFloat)lineSpacing
                                  sizeRange:(A_SSizeRange)sizeRange
                                 identifier:(NSString *)identifier
{
  A_SStackLayoutSpecStyle style = {
    .direction = A_SStackLayoutDirectionHorizontal,
    .flexWrap = A_SStackLayoutFlexWrapWrap,
    .alignContent = alignContent,
    .lineSpacing = lineSpacing,
  };

  CGSize subnodeSize = {50, 50};
  NSArray<A_SDisplayNode *> *subnodes = @[
                                         A_SDisplayNodeWithBackgroundColor([UIColor redColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor yellowColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor blueColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor magentaColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor greenColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor cyanColor], subnodeSize),
                                         ];

  [self testStackLayoutSpecWithStyle:style sizeRange:sizeRange subnodes:subnodes identifier:identifier];
}

- (void)testStackLayoutSpecWithAlignContent:(A_SStackLayoutAlignContent)alignContent
                                  sizeRange:(A_SSizeRange)sizeRange
                                 identifier:(NSString *)identifier
{
  [self testStackLayoutSpecWithAlignContent:alignContent lineSpacing:0.0 sizeRange:sizeRange identifier:identifier];
}

#pragma mark -

- (void)testDefaultStackLayoutElementFlexProperties
{
  A_SDisplayNode *displayNode = [[A_SDisplayNode alloc] init];
  
  XCTAssertEqual(displayNode.style.flexShrink, NO);
  XCTAssertEqual(displayNode.style.flexGrow, NO);
  
  const A_SDimension unconstrainedDimension = A_SDimensionAuto;
  const A_SDimension flexBasis = displayNode.style.flexBasis;
  XCTAssertEqual(flexBasis.unit, unconstrainedDimension.unit);
  XCTAssertEqual(flexBasis.value, unconstrainedDimension.value);
}

- (void)testUnderflowBehaviors
{
  // width 300px; height 0-300px
  static A_SSizeRange kSize = {{300, 0}, {300, 300}};
  [self testStackLayoutSpecWithJustify:A_SStackLayoutJustifyContentStart flexFactor:0 sizeRange:kSize identifier:@"justifyStart"];
  [self testStackLayoutSpecWithJustify:A_SStackLayoutJustifyContentCenter flexFactor:0 sizeRange:kSize identifier:@"justifyCenter"];
  [self testStackLayoutSpecWithJustify:A_SStackLayoutJustifyContentEnd flexFactor:0 sizeRange:kSize identifier:@"justifyEnd"];
  [self testStackLayoutSpecWithJustify:A_SStackLayoutJustifyContentStart flexFactor:1 sizeRange:kSize identifier:@"flex"];
  [self testStackLayoutSpecWithJustify:A_SStackLayoutJustifyContentSpaceBetween flexFactor:0 sizeRange:kSize identifier:@"justifySpaceBetween"];
  [self testStackLayoutSpecWithJustify:A_SStackLayoutJustifyContentSpaceAround flexFactor:0 sizeRange:kSize identifier:@"justifySpaceAround"];
}

- (void)testOverflowBehaviors
{
  // width 110px; height 0-300px
  static A_SSizeRange kSize = {{110, 0}, {110, 300}};
  [self testStackLayoutSpecWithJustify:A_SStackLayoutJustifyContentStart flexFactor:0 sizeRange:kSize identifier:@"justifyStart"];
  [self testStackLayoutSpecWithJustify:A_SStackLayoutJustifyContentCenter flexFactor:0 sizeRange:kSize identifier:@"justifyCenter"];
  [self testStackLayoutSpecWithJustify:A_SStackLayoutJustifyContentEnd flexFactor:0 sizeRange:kSize identifier:@"justifyEnd"];
  [self testStackLayoutSpecWithJustify:A_SStackLayoutJustifyContentStart flexFactor:1 sizeRange:kSize identifier:@"flex"];
  // On overflow, "space between" is identical to "content start"
  [self testStackLayoutSpecWithJustify:A_SStackLayoutJustifyContentSpaceBetween flexFactor:0 sizeRange:kSize identifier:@"justifyStart"];
  // On overflow, "space around" is identical to "content center"
  [self testStackLayoutSpecWithJustify:A_SStackLayoutJustifyContentSpaceAround flexFactor:0 sizeRange:kSize identifier:@"justifyCenter"];
}

- (void)testOverflowBehaviorsWhenAllFlexShrinkChildrenHaveBeenClampedToZeroButViolationStillExists
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize({50, 50}, 0);
  subnodes[1].style.flexShrink = 1;
  
  // Width is 75px--that's less than the sum of the widths of the children, which is 100px.
  static A_SSizeRange kSize = {{75, 0}, {75, 150}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testFlexWithUnequalIntrinsicSizes
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize({50, 50}, 1);
  setCGSizeToNode({150, 150}, subnodes[1]);

  // width 300px; height 0-150px.
  static A_SSizeRange kUnderflowSize = {{300, 0}, {300, 150}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kUnderflowSize subnodes:subnodes identifier:@"underflow"];
  
  // width 200px; height 0-150px.
  static A_SSizeRange kOverflowSize = {{200, 0}, {200, 150}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kOverflowSize subnodes:subnodes identifier:@"overflow"];
}

- (void)testCrossAxisSizeBehaviors
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionVertical};

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodes();
  setCGSizeToNode({50, 50}, subnodes[0]);
  setCGSizeToNode({100, 50}, subnodes[1]);
  setCGSizeToNode({150, 50}, subnodes[2]);
  
  // width 0-300px; height 300px
  static A_SSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kVariableHeight subnodes:subnodes identifier:@"variableHeight"];
  
  // width 300px; height 300px
  static A_SSizeRange kFixedHeight = {{300, 300}, {300, 300}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kFixedHeight subnodes:subnodes identifier:@"fixedHeight"];
}

- (void)testStackSpacing
{
  A_SStackLayoutSpecStyle style = {
    .direction = A_SStackLayoutDirectionVertical,
    .spacing = 10
  };

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodes();
  setCGSizeToNode({50, 50}, subnodes[0]);
  setCGSizeToNode({100, 50}, subnodes[1]);
  setCGSizeToNode({150, 50}, subnodes[2]);

  // width 0-300px; height 300px
  static A_SSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kVariableHeight subnodes:subnodes identifier:@"variableHeight"];
}

- (void)testStackSpacingWithChildrenHavingNilObjects
{
  // This should take a zero height since all children have a nil node. If it takes a height > 0, a blue background
  // will show up, hence failing the test.
  A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor blueColor]);

  A_SLayoutSpec *layoutSpec =
  [A_SInsetLayoutSpec
   insetLayoutSpecWithInsets:{10, 10, 10, 10}
   child:
   [A_SBackgroundLayoutSpec
    backgroundLayoutSpecWithChild:
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
     spacing:10
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsStretch
     children:@[]]
    background:backgroundNode]];
  
  // width 300px; height 0-300px
  static A_SSizeRange kVariableHeight = {{300, 0}, {300, 300}};
  [self testLayoutSpec:layoutSpec sizeRange:kVariableHeight subnodes:@[backgroundNode] identifier:@"variableHeight"];
}

- (void)testChildSpacing
{
  // width 0-INF; height 0-INF
  static A_SSizeRange kAnySize = {{0, 0}, {INFINITY, INFINITY}};
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionVertical};

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodes();
  setCGSizeToNode({50, 50}, subnodes[0]);
  setCGSizeToNode({100, 70}, subnodes[1]);
  setCGSizeToNode({150, 90}, subnodes[2]);
  
  subnodes[1].style.spacingBefore = 10;
  subnodes[2].style.spacingBefore = 20;
  [self testStackLayoutSpecWithStyle:style sizeRange:kAnySize subnodes:subnodes identifier:@"spacingBefore"];
  // Reset above spacing values
  subnodes[1].style.spacingBefore = 0;
  subnodes[2].style.spacingBefore = 0;

  subnodes[1].style.spacingAfter = 10;
  subnodes[2].style.spacingAfter = 20;
  [self testStackLayoutSpecWithStyle:style sizeRange:kAnySize subnodes:subnodes identifier:@"spacingAfter"];
  // Reset above spacing values
  subnodes[1].style.spacingAfter = 0;
  subnodes[2].style.spacingAfter = 0;
  
  style.spacing = 10;
  subnodes[1].style.spacingBefore = -10;
  subnodes[1].style.spacingAfter = -10;
  [self testStackLayoutSpecWithStyle:style sizeRange:kAnySize subnodes:subnodes identifier:@"spacingBalancedOut"];
}

- (void)testJustifiedCenterWithChildSpacing
{
  A_SStackLayoutSpecStyle style = {
    .direction = A_SStackLayoutDirectionVertical,
    .justifyContent = A_SStackLayoutJustifyContentCenter
  };

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodes();
  setCGSizeToNode({50, 50}, subnodes[0]);
  setCGSizeToNode({100, 70}, subnodes[1]);
  setCGSizeToNode({150, 90}, subnodes[2]);

  subnodes[0].style.spacingBefore = 0;
  subnodes[1].style.spacingBefore = 20;
  subnodes[2].style.spacingBefore = 30;

  // width 0-300px; height 300px
  static A_SSizeRange kVariableHeight = {{0, 300}, {300, 300}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kVariableHeight subnodes:subnodes identifier:@"variableHeight"];
}

- (void)testJustifiedSpaceBetweenWithOneChild
{
  A_SStackLayoutSpecStyle style = {
    .direction = A_SStackLayoutDirectionHorizontal,
    .justifyContent = A_SStackLayoutJustifyContentSpaceBetween
  };

  A_SDisplayNode *child = A_SDisplayNodeWithBackgroundColor([UIColor redColor], {50, 50});
  
  // width 300px; height 0-INF
  static A_SSizeRange kVariableHeight = {{300, 0}, {300, INFINITY}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kVariableHeight subnodes:@[child] identifier:nil];
}

- (void)testJustifiedSpaceAroundWithOneChild
{
  A_SStackLayoutSpecStyle style = {
    .direction = A_SStackLayoutDirectionHorizontal,
    .justifyContent = A_SStackLayoutJustifyContentSpaceAround
  };
  
  A_SDisplayNode *child = A_SDisplayNodeWithBackgroundColor([UIColor redColor], {50, 50});
  
  // width 300px; height 0-INF
  static A_SSizeRange kVariableHeight = {{300, 0}, {300, INFINITY}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kVariableHeight subnodes:@[child] identifier:nil];
}

- (void)testJustifiedSpaceBetweenWithRemainingSpace
{
  // width 301px; height 0-300px;
  static A_SSizeRange kSize = {{301, 0}, {301, 300}};
  [self testStackLayoutSpecWithJustify:A_SStackLayoutJustifyContentSpaceBetween flexFactor:0 sizeRange:kSize identifier:nil];
}

- (void)testJustifiedSpaceAroundWithRemainingSpace
{
  // width 305px; height 0-300px;
  static A_SSizeRange kSize = {{305, 0}, {305, 300}};
  [self testStackLayoutSpecWithJustify:A_SStackLayoutJustifyContentSpaceAround flexFactor:0 sizeRange:kSize identifier:nil];
}

- (void)testChildThatChangesCrossSizeWhenMainSizeIsFlexed
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};

  A_SDisplayNode *subnode1 = A_SDisplayNodeWithBackgroundColor([UIColor blueColor]);
  A_SDisplayNode *subnode2 = A_SDisplayNodeWithBackgroundColor([UIColor redColor], {50, 50});
  
  A_SRatioLayoutSpec *child1 = [A_SRatioLayoutSpec ratioLayoutSpecWithRatio:1.5 child:subnode1];
  child1.style.flexBasis = A_SDimensionMakeWithFraction(1);
  child1.style.flexGrow = 1;
  child1.style.flexShrink = 1;
  
  static A_SSizeRange kFixedWidth = {{150, 0}, {150, INFINITY}};
  [self testStackLayoutSpecWithStyle:style children:@[child1, subnode2] sizeRange:kFixedWidth subnodes:@[subnode1, subnode2] identifier:nil];
}

- (void)testAlignCenterWithFlexedMainDimension
{
  A_SStackLayoutSpecStyle style = {
    .direction = A_SStackLayoutDirectionVertical,
    .alignItems = A_SStackLayoutAlignItemsCenter
  };

  NSArray<A_SDisplayNode *> *subnodes = @[
    A_SDisplayNodeWithBackgroundColor([UIColor redColor], {100, 100}),
    A_SDisplayNodeWithBackgroundColor([UIColor blueColor], {50, 50})
  ];
  subnodes[0].style.flexShrink = 1;
  subnodes[1].style.flexShrink = 1;

  static A_SSizeRange kFixedWidth = {{150, 0}, {150, 100}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kFixedWidth subnodes:subnodes identifier:nil];
}

- (void)testAlignCenterWithIndefiniteCrossDimension
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};

  A_SDisplayNode *subnode1 = A_SDisplayNodeWithBackgroundColor([UIColor redColor], {100, 100});
  
  A_SDisplayNode *subnode2 = A_SDisplayNodeWithBackgroundColor([UIColor blueColor], {50, 50});
  subnode2.style.alignSelf = A_SStackLayoutAlignSelfCenter;

  NSArray<A_SDisplayNode *> *subnodes = @[subnode1, subnode2];
  static A_SSizeRange kFixedWidth = {{150, 0}, {150, INFINITY}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kFixedWidth subnodes:subnodes identifier:nil];
}

- (void)testAlignedStart
{
  A_SStackLayoutSpecStyle style = {
    .direction = A_SStackLayoutDirectionVertical,
    .justifyContent = A_SStackLayoutJustifyContentCenter,
    .alignItems = A_SStackLayoutAlignItemsStart
  };

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodes();
  setCGSizeToNode({50, 50}, subnodes[0]);
  setCGSizeToNode({100, 70}, subnodes[1]);
  setCGSizeToNode({150, 90}, subnodes[2]);
  
  subnodes[0].style.spacingBefore = 0;
  subnodes[1].style.spacingBefore = 20;
  subnodes[2].style.spacingBefore = 30;

  static A_SSizeRange kExactSize = {{300, 300}, {300, 300}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kExactSize subnodes:subnodes identifier:nil];
}

- (void)testAlignedEnd
{
  A_SStackLayoutSpecStyle style = {
    .direction = A_SStackLayoutDirectionVertical,
    .justifyContent = A_SStackLayoutJustifyContentCenter,
    .alignItems = A_SStackLayoutAlignItemsEnd
  };
  
  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodes();
  setCGSizeToNode({50, 50}, subnodes[0]);
  setCGSizeToNode({100, 70}, subnodes[1]);
  setCGSizeToNode({150, 90}, subnodes[2]);
  
  subnodes[0].style.spacingBefore = 0;
  subnodes[1].style.spacingBefore = 20;
  subnodes[2].style.spacingBefore = 30;

  static A_SSizeRange kExactSize = {{300, 300}, {300, 300}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kExactSize subnodes:subnodes identifier:nil];
}

- (void)testAlignedCenter
{
  A_SStackLayoutSpecStyle style = {
    .direction = A_SStackLayoutDirectionVertical,
    .justifyContent = A_SStackLayoutJustifyContentCenter,
    .alignItems = A_SStackLayoutAlignItemsCenter
  };

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodes();
  setCGSizeToNode({50, 50}, subnodes[0]);
  setCGSizeToNode({100, 70}, subnodes[1]);
  setCGSizeToNode({150, 90}, subnodes[2]);
  
  subnodes[0].style.spacingBefore = 0;
  subnodes[1].style.spacingBefore = 20;
  subnodes[2].style.spacingBefore = 30;

  static A_SSizeRange kExactSize = {{300, 300}, {300, 300}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kExactSize subnodes:subnodes identifier:nil];
}

- (void)testAlignedStretchNoChildExceedsMin
{
  A_SStackLayoutSpecStyle style = {
    .direction = A_SStackLayoutDirectionVertical,
    .justifyContent = A_SStackLayoutJustifyContentCenter,
    .alignItems = A_SStackLayoutAlignItemsStretch
  };

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodes();
  setCGSizeToNode({50, 50}, subnodes[0]);
  setCGSizeToNode({100, 70}, subnodes[1]);
  setCGSizeToNode({150, 90}, subnodes[2]);

  subnodes[0].style.spacingBefore = 0;
  subnodes[1].style.spacingBefore = 20;
  subnodes[2].style.spacingBefore = 30;

  static A_SSizeRange kVariableSize = {{200, 200}, {300, 300}};
  // all children should be 200px wide
  [self testStackLayoutSpecWithStyle:style sizeRange:kVariableSize subnodes:subnodes identifier:nil];
}

- (void)testAlignedStretchOneChildExceedsMin
{
  A_SStackLayoutSpecStyle style = {
    .direction = A_SStackLayoutDirectionVertical,
    .justifyContent = A_SStackLayoutJustifyContentCenter,
    .alignItems = A_SStackLayoutAlignItemsStretch
  };

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodes();
  setCGSizeToNode({50, 50}, subnodes[0]);
  setCGSizeToNode({100, 70}, subnodes[1]);
  setCGSizeToNode({150, 90}, subnodes[2]);
  
  subnodes[0].style.spacingBefore = 0;
  subnodes[1].style.spacingBefore = 20;
  subnodes[2].style.spacingBefore = 30;

  static A_SSizeRange kVariableSize = {{50, 50}, {300, 300}};
  // all children should be 150px wide
  [self testStackLayoutSpecWithStyle:style sizeRange:kVariableSize subnodes:subnodes identifier:nil];
}

- (void)testEmptyStack
{
  static A_SSizeRange kVariableSize = {{50, 50}, {300, 300}};
  [self testStackLayoutSpecWithStyle:{} sizeRange:kVariableSize subnodes:@[] identifier:nil];
}

- (void)testFixedFlexBasisAppliedWhenFlexingItems
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize({50, 50}, 0);
  setCGSizeToNode({150, 150}, subnodes[1]);

  for (A_SDisplayNode *subnode in subnodes) {
    subnode.style.flexGrow = 1;
    subnode.style.flexBasis = A_SDimensionMakeWithPoints(10);
  }

  // width 300px; height 0-150px.
  static A_SSizeRange kUnderflowSize = {{300, 0}, {300, 150}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kUnderflowSize subnodes:subnodes identifier:@"underflow"];

  // width 200px; height 0-150px.
  static A_SSizeRange kOverflowSize = {{200, 0}, {200, 150}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kOverflowSize subnodes:subnodes identifier:@"overflow"];
}

- (void)testFractionalFlexBasisResolvesAgainstParentSize
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize({50, 50}, 0);
  for (A_SDisplayNode *subnode in subnodes) {
    subnode.style.flexGrow = 1;
  }

  // This should override the intrinsic size of 50pts and instead compute to 50% = 100pts.
  // The result should be that the red box is twice as wide as the blue and gree boxes after flexing.
  subnodes[0].style.flexBasis = A_SDimensionMakeWithFraction(0.5);

  static A_SSizeRange kSize = {{200, 0}, {200, INFINITY}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testFixedFlexBasisOverridesIntrinsicSizeForNonFlexingChildren
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodes();
  setCGSizeToNode({50, 50}, subnodes[0]);
  setCGSizeToNode({150, 150}, subnodes[1]);
  setCGSizeToNode({150, 50}, subnodes[2]);

  for (A_SDisplayNode *subnode in subnodes) {
    subnode.style.flexBasis = A_SDimensionMakeWithPoints(20);
  }
  
  static A_SSizeRange kSize = {{300, 0}, {300, 150}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testCrossAxisStretchingOccursAfterStackAxisFlexing
{
  // If cross axis stretching occurred *before* flexing, then the blue child would be stretched to 3000 points tall.
  // Instead it should be stretched to 300 points tall, matching the red child and not overlapping the green inset.

  NSArray<A_SDisplayNode *> *subnodes = @[
    A_SDisplayNodeWithBackgroundColor([UIColor greenColor]),           // Inset background node
    A_SDisplayNodeWithBackgroundColor([UIColor blueColor]),            // child1 of stack
    A_SDisplayNodeWithBackgroundColor([UIColor redColor], {500, 500})  // child2 of stack
  ];
  
  subnodes[1].style.width = A_SDimensionMake(10);
  
  A_SDisplayNode *child2 = subnodes[2];
  child2.style.flexGrow = 1;
  child2.style.flexShrink = 1;

  // If cross axis stretching occurred *before* flexing, then the blue child would be stretched to 3000 points tall.
  // Instead it should be stretched to 300 points tall, matching the red child and not overlapping the green inset.
  A_SLayoutSpec *layoutSpec =
  [A_SBackgroundLayoutSpec
   backgroundLayoutSpecWithChild:
   [A_SInsetLayoutSpec
    insetLayoutSpecWithInsets:UIEdgeInsetsMake(10, 10, 10, 10)
    child:
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
     spacing:0
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsStretch
     children:@[subnodes[1], child2]]
    ]
   background:subnodes[0]];

  static A_SSizeRange kSize = {{300, 0}, {300, INFINITY}};
  [self testLayoutSpec:layoutSpec sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testPositiveViolationIsDistributedEqually
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};
  
  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize({50, 50}, 0);
  subnodes[0].style.flexGrow = 1;
  subnodes[2].style.flexGrow = 1;

  // In this scenario a width of 350 results in a positive violation of 200.
  // Due to each flexible subnode specifying a flex grow factor of 1 the violation will be distributed evenly.
  static A_SSizeRange kSize = {{350, 350}, {350, 350}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testPositiveViolationIsDistributedEquallyWithArbitraryFloats
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};
  
  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize({50, 50}, 0);
  subnodes[0].style.flexGrow = 0.5;
  subnodes[2].style.flexGrow = 0.5;
  
  // In this scenario a width of 350 results in a positive violation of 200.
  // Due to each flexible child component specifying a flex grow factor of 0.5 the violation will be distributed evenly.
  static A_SSizeRange kSize = {{350, 350}, {350, 350}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testPositiveViolationIsDistributedProportionally
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionVertical};

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize({50, 50}, 0);
  subnodes[0].style.flexGrow = 1;
  subnodes[1].style.flexGrow = 2;
  subnodes[2].style.flexGrow = 1;

  // In this scenario a width of 350 results in a positive violation of 200.
  // The first and third subnodes specify a flex grow factor of 1 and will flex by 50.
  // The second subnode specifies a flex grow factor of 2 and will flex by 100.
  static A_SSizeRange kSize = {{350, 350}, {350, 350}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testPositiveViolationIsDistributedProportionallyWithArbitraryFloats
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionVertical};

  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize({50, 50}, 0);
  subnodes[0].style.flexGrow = 0.25;
  subnodes[1].style.flexGrow = 0.50;
  subnodes[2].style.flexGrow = 0.25;

  // In this scenario a width of 350 results in a positive violation of 200.
  // The first and third child components specify a flex grow factor of 0.25 and will flex by 50.
  // The second child component specifies a flex grow factor of 0.25 and will flex by 100.
  static A_SSizeRange kSize = {{350, 350}, {350, 350}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testPositiveViolationIsDistributedEquallyAmongMixedChildren
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};
  
  const CGSize kSubnodeSize = {50, 50};
  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize(kSubnodeSize, 0);
  subnodes = [subnodes arrayByAddingObject:A_SDisplayNodeWithBackgroundColor([UIColor yellowColor], kSubnodeSize)];
  
  subnodes[0].style.flexShrink = 1;
  subnodes[1].style.flexGrow = 1;
  subnodes[2].style.flexShrink = 0;
  subnodes[3].style.flexGrow = 1;
  
  // In this scenario a width of 400 results in a positive violation of 200.
  // The first and third subnode specify a flex shrink factor of 1 and 0, respectively. They won't flex.
  // The second and fourth subnode specify a flex grow factor of 1 and will flex by 100.
  static A_SSizeRange kSize = {{400, 400}, {400, 400}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testPositiveViolationIsDistributedEquallyAmongMixedChildrenWithArbitraryFloats
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};
  
  const CGSize kSubnodeSize = {50, 50};
  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize(kSubnodeSize, 0);
  subnodes = [subnodes arrayByAddingObject:A_SDisplayNodeWithBackgroundColor([UIColor yellowColor], kSubnodeSize)];
  
  subnodes[0].style.flexShrink = 1.0;
  subnodes[1].style.flexGrow = 0.5;
  subnodes[2].style.flexShrink = 0.0;
  subnodes[3].style.flexGrow = 0.5;
  
  // In this scenario a width of 400 results in a positive violation of 200.
  // The first and third child components specify a flex shrink factor of 1 and 0, respectively. They won't flex.
  // The second and fourth child components specify a flex grow factor of 0.5 and will flex by 100.
  static A_SSizeRange kSize = {{400, 400}, {400, 400}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testPositiveViolationIsDistributedProportionallyAmongMixedChildren
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionVertical};
  
  const CGSize kSubnodeSize = {50, 50};
  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize(kSubnodeSize, 0);
  subnodes = [subnodes arrayByAddingObject:A_SDisplayNodeWithBackgroundColor([UIColor yellowColor], kSubnodeSize)];
  
  subnodes[0].style.flexShrink = 1;
  subnodes[1].style.flexGrow = 3;
  subnodes[2].style.flexShrink = 0;
  subnodes[3].style.flexGrow = 1;
  
  // In this scenario a width of 400 results in a positive violation of 200.
  // The first and third subnodes specify a flex shrink factor of 1 and 0, respectively. They won't flex.
  // The second child subnode specifies a flex grow factor of 3 and will flex by 150.
  // The fourth child subnode specifies a flex grow factor of 1 and will flex by 50.
  static A_SSizeRange kSize = {{400, 400}, {400, 400}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testPositiveViolationIsDistributedProportionallyAmongMixedChildrenWithArbitraryFloats
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionVertical};
  
  const CGSize kSubnodeSize = {50, 50};
  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize(kSubnodeSize, 0);
  subnodes = [subnodes arrayByAddingObject:A_SDisplayNodeWithBackgroundColor([UIColor yellowColor], kSubnodeSize)];
  
  subnodes[0].style.flexShrink = 1.0;
  subnodes[1].style.flexGrow = 0.75;
  subnodes[2].style.flexShrink = 0.0;
  subnodes[3].style.flexGrow = 0.25;
  
  // In this scenario a width of 400 results in a positive violation of 200.
  // The first and third child components specify a flex shrink factor of 1 and 0, respectively. They won't flex.
  // The second child component specifies a flex grow factor of 0.75 and will flex by 150.
  // The fourth child component specifies a flex grow factor of 0.25 and will flex by 50.
  static A_SSizeRange kSize = {{400, 400}, {400, 400}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testRemainingViolationIsAppliedProperlyToFirstFlexibleChild
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionVertical};
  
  NSArray<A_SDisplayNode *> *subnodes = @[
    A_SDisplayNodeWithBackgroundColor([UIColor greenColor], {50, 25}),
    A_SDisplayNodeWithBackgroundColor([UIColor blueColor], {50, 0}),
    A_SDisplayNodeWithBackgroundColor([UIColor redColor], {50, 100})
  ];

  subnodes[0].style.flexGrow = 0;
  subnodes[1].style.flexGrow = 1;
  subnodes[2].style.flexGrow = 1;
  
  // In this scenario a width of 300 results in a positive violation of 175.
  // The second and third subnodes specify a flex grow factor of 1 and will flex by 88 and 87, respectively.
  static A_SSizeRange kSize = {{300, 300}, {300, 300}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testRemainingViolationIsAppliedProperlyToFirstFlexibleChildWithArbitraryFloats
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionVertical};
  
  NSArray<A_SDisplayNode *> *subnodes = @[
    A_SDisplayNodeWithBackgroundColor([UIColor greenColor], {50, 25}),
    A_SDisplayNodeWithBackgroundColor([UIColor blueColor], {50, 0}),
    A_SDisplayNodeWithBackgroundColor([UIColor redColor], {50, 100})
  ];

  subnodes[0].style.flexGrow = 0.0;
  subnodes[1].style.flexGrow = 0.5;
  subnodes[2].style.flexGrow = 0.5;
  
  // In this scenario a width of 300 results in a positive violation of 175.
  // The second and third child components specify a flex grow factor of 0.5 and will flex by 88 and 87, respectively.
  static A_SSizeRange kSize = {{300, 300}, {300, 300}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testNegativeViolationIsDistributedBasedOnSize
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};
  
  NSArray<A_SDisplayNode *> *subnodes = @[
    A_SDisplayNodeWithBackgroundColor([UIColor greenColor], {300, 50}),
    A_SDisplayNodeWithBackgroundColor([UIColor blueColor], {100, 50}),
    A_SDisplayNodeWithBackgroundColor([UIColor redColor], {200, 50})
  ];
  
  subnodes[0].style.flexShrink = 1;
  subnodes[1].style.flexShrink = 0;
  subnodes[2].style.flexShrink = 1;

  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third subnodes specify a flex shrink factor of 1 and will flex by -120 and -80, respectively.
  static A_SSizeRange kSize = {{400, 400}, {400, 400}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testNegativeViolationIsDistributedBasedOnSizeWithArbitraryFloats
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};
  
  NSArray<A_SDisplayNode *> *subnodes = @[
    A_SDisplayNodeWithBackgroundColor([UIColor greenColor], {300, 50}),
    A_SDisplayNodeWithBackgroundColor([UIColor blueColor], {100, 50}),
    A_SDisplayNodeWithBackgroundColor([UIColor redColor], {200, 50})
  ];
  
  subnodes[0].style.flexShrink = 0.5;
  subnodes[1].style.flexShrink = 0.0;
  subnodes[2].style.flexShrink = 0.5;

  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 0.5 and will flex by -120 and -80, respectively.
  static A_SSizeRange kSize = {{400, 400}, {400, 400}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactor
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionVertical};
  
  NSArray<A_SDisplayNode *> *subnodes = @[
    A_SDisplayNodeWithBackgroundColor([UIColor greenColor], {50, 300}),
    A_SDisplayNodeWithBackgroundColor([UIColor blueColor], {50, 100}),
    A_SDisplayNodeWithBackgroundColor([UIColor redColor], {50, 200})
  ];
  
  subnodes[0].style.flexShrink = 2;
  subnodes[1].style.flexShrink = 1;
  subnodes[2].style.flexShrink = 2;

  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third subnodes specify a flex shrink factor of 2 and will flex by -109 and -72, respectively.
  // The second subnode specifies a flex shrink factor of 1 and will flex by -18.
  static A_SSizeRange kSize = {{400, 400}, {400, 400}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorWithArbitraryFloats
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionVertical};
  
  NSArray<A_SDisplayNode *> *subnodes = @[
    A_SDisplayNodeWithBackgroundColor([UIColor greenColor], {50, 300}),
    A_SDisplayNodeWithBackgroundColor([UIColor blueColor], {50, 100}),
    A_SDisplayNodeWithBackgroundColor([UIColor redColor], {50, 200})
  ];
  
  subnodes[0].style.flexShrink = 0.4;
  subnodes[1].style.flexShrink = 0.2;
  subnodes[2].style.flexShrink = 0.4;

  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 0.4 and will flex by -109 and -72, respectively.
  // The second child component specifies a flex shrink factor of 0.2 and will flex by -18.
  static A_SSizeRange kSize = {{400, 400}, {400, 400}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAmongMixedChildrenChildren
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};
  
  const CGSize kSubnodeSize = {150, 50};
  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize(kSubnodeSize, 0);
  subnodes = [subnodes arrayByAddingObject:A_SDisplayNodeWithBackgroundColor([UIColor yellowColor], kSubnodeSize)];
  
  subnodes[0].style.flexGrow = 1;
  subnodes[1].style.flexShrink = 1;
  subnodes[2].style.flexGrow = 0;
  subnodes[3].style.flexShrink = 1;
  
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third subnodes specify a flex grow factor of 1 and 0, respectively. They won't flex.
  // The second and fourth subnodes specify a flex grow factor of 1 and will flex by -100.
  static A_SSizeRange kSize = {{400, 400}, {400, 400}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAmongMixedChildrenWithArbitraryFloats
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};
  
  const CGSize kSubnodeSize = {150, 50};
  NSArray<A_SDisplayNode *> *subnodes = defaultSubnodesWithSameSize(kSubnodeSize, 0);
  subnodes = [subnodes arrayByAddingObject:A_SDisplayNodeWithBackgroundColor([UIColor yellowColor], kSubnodeSize)];
  
  subnodes[0].style.flexGrow = 1.0;
  subnodes[1].style.flexShrink = 0.5;
  subnodes[2].style.flexGrow = 0.0;
  subnodes[3].style.flexShrink = 0.5;
  
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex grow factor of 1 and 0, respectively. They won't flex.
  // The second and fourth child components specify a flex shrink factor of 0.5 and will flex by -100.
  static A_SSizeRange kSize = {{400, 400}, {400, 400}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorAmongMixedChildren
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionVertical};
  
  NSArray<A_SDisplayNode *> *subnodes = @[
    A_SDisplayNodeWithBackgroundColor([UIColor greenColor], {50, 150}),
    A_SDisplayNodeWithBackgroundColor([UIColor blueColor], {50, 100}),
    A_SDisplayNodeWithBackgroundColor([UIColor redColor], {50, 150}),
    A_SDisplayNodeWithBackgroundColor([UIColor yellowColor], {50, 200})
  ];
  
  subnodes[0].style.flexGrow = 1;
  subnodes[1].style.flexShrink = 1;
  subnodes[2].style.flexGrow = 0;
  subnodes[3].style.flexShrink = 3;
  
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third subnodes specify a flex grow factor of 1 and 0, respectively. They won't flex.
  // The second subnode specifies a flex grow factor of 1 and will flex by -28.
  // The fourth subnode specifies a flex grow factor of 3 and will flex by -171.
  static A_SSizeRange kSize = {{400, 400}, {400, 400}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorAmongMixedChildrenArbitraryFloats
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionVertical};
  
  NSArray<A_SDisplayNode *> *subnodes = @[
    A_SDisplayNodeWithBackgroundColor([UIColor greenColor], {50, 150}),
    A_SDisplayNodeWithBackgroundColor([UIColor blueColor], {50, 100}),
    A_SDisplayNodeWithBackgroundColor([UIColor redColor], {50, 150}),
    A_SDisplayNodeWithBackgroundColor([UIColor yellowColor], {50, 200})
  ];
  
  subnodes[0].style.flexGrow = 1.0;
  subnodes[1].style.flexShrink = 0.25;
  subnodes[2].style.flexGrow = 0.0;
  subnodes[3].style.flexShrink = 0.75;
  
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex grow factor of 1 and 0, respectively. They won't flex.
  // The second child component specifies a flex shrink factor of 0.25 and will flex by -28.
  // The fourth child component specifies a flex shrink factor of 0.75 and will flex by -171.
  static A_SSizeRange kSize = {{400, 400}, {400, 400}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorDoesNotShrinkToZero
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};
  
  NSArray<A_SDisplayNode *> *subnodes = @[
    A_SDisplayNodeWithBackgroundColor([UIColor greenColor], {300, 50}),
    A_SDisplayNodeWithBackgroundColor([UIColor blueColor], {100, 50}),
    A_SDisplayNodeWithBackgroundColor([UIColor redColor], {200, 50})
  ];
  
  subnodes[0].style.flexShrink = 1;
  subnodes[1].style.flexShrink = 2;
  subnodes[2].style.flexShrink = 1;
  
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third subnodes specify a flex shrink factor of 1 and will flex by 50.
  // The second subnode specifies a flex shrink factor of 2 and will flex by -57. It will have a width of 43.
  static A_SSizeRange kSize = {{400, 400}, {400, 400}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testNegativeViolationIsDistributedBasedOnSizeAndFlexFactorDoesNotShrinkToZeroWithArbitraryFloats
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};
  
  NSArray<A_SDisplayNode *> *subnodes = @[
    A_SDisplayNodeWithBackgroundColor([UIColor greenColor], {300, 50}),
    A_SDisplayNodeWithBackgroundColor([UIColor blueColor], {100, 50}),
    A_SDisplayNodeWithBackgroundColor([UIColor redColor], {200, 50})
  ];
  
  subnodes[0].style.flexShrink = 0.25;
  subnodes[1].style.flexShrink = 0.50;
  subnodes[2].style.flexShrink = 0.25;
  
  // In this scenario a width of 400 results in a negative violation of 200.
  // The first and third child components specify a flex shrink factor of 0.25 and will flex by 50.
  // The second child specifies a flex shrink factor of 0.50 and will flex by -57. It will have a width of 43.
  static A_SSizeRange kSize = {{400, 400}, {400, 400}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}


- (void)testNegativeViolationAndFlexFactorIsNotRespected
{
  A_SStackLayoutSpecStyle style = {.direction = A_SStackLayoutDirectionHorizontal};
  
  NSArray<A_SDisplayNode *> *subnodes = @[
    A_SDisplayNodeWithBackgroundColor([UIColor redColor], {50, 50}),
    A_SDisplayNodeWithBackgroundColor([UIColor yellowColor], CGSizeZero),
  ];
  
  subnodes[0].style.flexShrink = 0;
  subnodes[1].style.flexShrink = 1;
  
  // In this scenario a width of 40 results in a negative violation of 10.
  // The first child will not flex.
  // The second child specifies a flex shrink factor of 1 but it has a zero size, so the factor won't be respected and it will not shrink.
  static A_SSizeRange kSize = {{40, 50}, {40, 50}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testNestedStackLayoutStretchDoesNotViolateWidth
{
  A_SStackLayoutSpec *stackLayoutSpec = [[A_SStackLayoutSpec alloc] init]; // Default direction is horizontal
  stackLayoutSpec.direction = A_SStackLayoutDirectionHorizontal;
  stackLayoutSpec.alignItems = A_SStackLayoutAlignItemsStretch;
  stackLayoutSpec.style.width = A_SDimensionMake(100);
  stackLayoutSpec.style.height = A_SDimensionMake(100);
  
  A_SDisplayNode *child = A_SDisplayNodeWithBackgroundColor([UIColor redColor], {50, 50});
  stackLayoutSpec.children = @[child];
  
  static A_SSizeRange kSize = {{0, 0}, {300, INFINITY}};
  [self testStackLayoutSpec:stackLayoutSpec sizeRange:kSize subnodes:@[child] identifier:nil];
}

- (void)testHorizontalAndVerticalAlignments
{
  [self testStackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal itemsHorizontalAlignment:A_SHorizontalAlignmentLeft itemsVerticalAlignment:A_SVerticalAlignmentTop identifier:@"horizontalTopLeft"];
  [self testStackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal itemsHorizontalAlignment:A_SHorizontalAlignmentMiddle itemsVerticalAlignment:A_SVerticalAlignmentCenter identifier:@"horizontalCenter"];
  [self testStackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal itemsHorizontalAlignment:A_SHorizontalAlignmentRight itemsVerticalAlignment:A_SVerticalAlignmentBottom identifier:@"horizontalBottomRight"];
  [self testStackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical itemsHorizontalAlignment:A_SHorizontalAlignmentLeft itemsVerticalAlignment:A_SVerticalAlignmentTop identifier:@"verticalTopLeft"];
  [self testStackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical itemsHorizontalAlignment:A_SHorizontalAlignmentMiddle itemsVerticalAlignment:A_SVerticalAlignmentCenter identifier:@"verticalCenter"];
  [self testStackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical itemsHorizontalAlignment:A_SHorizontalAlignmentRight itemsVerticalAlignment:A_SVerticalAlignmentBottom identifier:@"verticalBottomRight"];
}

- (void)testDirectionChangeAfterSettingHorizontalAndVerticalAlignments
{
  A_SStackLayoutSpec *stackLayoutSpec = [[A_SStackLayoutSpec alloc] init]; // Default direction is horizontal
  stackLayoutSpec.horizontalAlignment = A_SHorizontalAlignmentRight;
  stackLayoutSpec.verticalAlignment = A_SVerticalAlignmentCenter;
  XCTAssertEqual(stackLayoutSpec.alignItems, A_SStackLayoutAlignItemsCenter);
  XCTAssertEqual(stackLayoutSpec.justifyContent, A_SStackLayoutJustifyContentEnd);
  
  stackLayoutSpec.direction = A_SStackLayoutDirectionVertical;
  XCTAssertEqual(stackLayoutSpec.alignItems, A_SStackLayoutAlignItemsEnd);
  XCTAssertEqual(stackLayoutSpec.justifyContent, A_SStackLayoutJustifyContentCenter);
}

- (void)testAlignItemsAndJustifyContentRestrictionsIfHorizontalAndVerticalAlignmentsAreUsed
{
  A_SStackLayoutSpec *stackLayoutSpec = [[A_SStackLayoutSpec alloc] init];

  // No assertions should be thrown here because alignments are not used
  stackLayoutSpec.alignItems = A_SStackLayoutAlignItemsEnd;
  stackLayoutSpec.justifyContent = A_SStackLayoutJustifyContentEnd;

  // Set alignments and assert that assertions are thrown
  stackLayoutSpec.horizontalAlignment = A_SHorizontalAlignmentMiddle;
  stackLayoutSpec.verticalAlignment = A_SVerticalAlignmentCenter;
  XCTAssertThrows(stackLayoutSpec.alignItems = A_SStackLayoutAlignItemsEnd);
  XCTAssertThrows(stackLayoutSpec.justifyContent = A_SStackLayoutJustifyContentEnd);

  // Unset alignments. alignItems and justifyContent should not be changed
  stackLayoutSpec.horizontalAlignment = A_SHorizontalAlignmentNone;
  stackLayoutSpec.verticalAlignment = A_SVerticalAlignmentNone;
  XCTAssertEqual(stackLayoutSpec.alignItems, A_SStackLayoutAlignItemsCenter);
  XCTAssertEqual(stackLayoutSpec.justifyContent, A_SStackLayoutJustifyContentCenter);

  // Now that alignments are none, setting alignItems and justifyContent should be allowed again
  stackLayoutSpec.alignItems = A_SStackLayoutAlignItemsEnd;
  stackLayoutSpec.justifyContent = A_SStackLayoutJustifyContentEnd;
  XCTAssertEqual(stackLayoutSpec.alignItems, A_SStackLayoutAlignItemsEnd);
  XCTAssertEqual(stackLayoutSpec.justifyContent, A_SStackLayoutJustifyContentEnd);
}

#pragma mark - Baseline alignment tests

- (void)testBaselineAlignment
{
  [self testStackLayoutSpecWithBaselineAlignment:A_SStackLayoutAlignItemsBaselineFirst identifier:@"baselineFirst"];
  [self testStackLayoutSpecWithBaselineAlignment:A_SStackLayoutAlignItemsBaselineLast identifier:@"baselineLast"];
}

- (void)testNestedBaselineAlignments
{
  NSArray<A_STextNode *> *textNodes = defaultTextNodes();
  
  A_SDisplayNode *stretchedNode = [[A_SDisplayNode alloc] init];
  stretchedNode.layerBacked = YES;
  stretchedNode.backgroundColor = [UIColor greenColor];
  stretchedNode.style.alignSelf = A_SStackLayoutAlignSelfStretch;
  stretchedNode.style.height = A_SDimensionMake(100);
  
  A_SStackLayoutSpec *verticalStack = [A_SStackLayoutSpec verticalStackLayoutSpec];
  verticalStack.children = @[stretchedNode, textNodes[1]];
  verticalStack.style.flexShrink = 1.0;
  
  A_SStackLayoutSpec *horizontalStack = [A_SStackLayoutSpec horizontalStackLayoutSpec];
  horizontalStack.children = @[textNodes[0], verticalStack];
  horizontalStack.alignItems = A_SStackLayoutAlignItemsBaselineLast;
  
  NSArray<A_SDisplayNode *> *subnodes = @[textNodes[0], textNodes[1], stretchedNode];
  
  static A_SSizeRange kSize = A_SSizeRangeMake(CGSizeMake(150, 0), CGSizeMake(150, CGFLOAT_MAX));
  [self testStackLayoutSpec:horizontalStack sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testBaselineAlignmentWithSpaceBetween
{
  NSArray<A_STextNode *> *textNodes = defaultTextNodes();
  
  A_SStackLayoutSpec *stackLayoutSpec = [A_SStackLayoutSpec horizontalStackLayoutSpec];
  stackLayoutSpec.children = textNodes;
  stackLayoutSpec.alignItems = A_SStackLayoutAlignItemsBaselineFirst;
  stackLayoutSpec.justifyContent = A_SStackLayoutJustifyContentSpaceBetween;
  
  static A_SSizeRange kSize = A_SSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX));
  [self testStackLayoutSpec:stackLayoutSpec sizeRange:kSize subnodes:textNodes identifier:nil];
}

- (void)testBaselineAlignmentWithStretchedItem
{
  NSArray<A_STextNode *> *textNodes = defaultTextNodes();
  
  A_SDisplayNode *stretchedNode = [[A_SDisplayNode alloc] init];
  stretchedNode.layerBacked = YES;
  stretchedNode.backgroundColor = [UIColor greenColor];
  stretchedNode.style.alignSelf = A_SStackLayoutAlignSelfStretch;
  stretchedNode.style.flexShrink = 1.0;
  stretchedNode.style.flexGrow = 1.0;
  
  NSMutableArray<A_SDisplayNode *> *children = [NSMutableArray arrayWithArray:textNodes];
  [children insertObject:stretchedNode atIndex:1];
  
  A_SStackLayoutSpec *stackLayoutSpec = [A_SStackLayoutSpec horizontalStackLayoutSpec];
  stackLayoutSpec.children = children;
  stackLayoutSpec.alignItems = A_SStackLayoutAlignItemsBaselineLast;
  stackLayoutSpec.justifyContent = A_SStackLayoutJustifyContentSpaceBetween;
  
  static A_SSizeRange kSize = A_SSizeRangeMake(CGSizeMake(300, 0), CGSizeMake(300, CGFLOAT_MAX));
  [self testStackLayoutSpec:stackLayoutSpec sizeRange:kSize subnodes:children identifier:nil];
}

#pragma mark - Flex wrap and item spacings test

- (void)testFlexWrapWithItemSpacings
{
  A_SStackLayoutSpecStyle style = {
    .spacing = 50,
    .direction = A_SStackLayoutDirectionHorizontal,
    .flexWrap = A_SStackLayoutFlexWrapWrap,
    .alignContent = A_SStackLayoutAlignContentStart,
    .lineSpacing = 5,
  };

  CGSize subnodeSize = {50, 50};
  NSArray<A_SDisplayNode *> *subnodes = @[
                                         A_SDisplayNodeWithBackgroundColor([UIColor redColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor yellowColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor blueColor], subnodeSize),
                                         ];

  for (A_SDisplayNode *subnode in subnodes) {
    subnode.style.spacingBefore = 5;
    subnode.style.spacingAfter = 5;
  }

  // 3 items, each item has a size of {50, 50}
  // width is 230px, enough to fit all items without taking all spacings into account
  // Test that all spacings are included and therefore the last item is pushed to a second line.
  // See: https://github.com/Tex_tureGroup/Tex_ture/pull/472
  static A_SSizeRange kSize = {{230, 300}, {230, 300}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

- (void)testFlexWrapWithItemSpacingsBeingResetOnNewLines
{
  A_SStackLayoutSpecStyle style = {
    .spacing = 5,
    .direction = A_SStackLayoutDirectionHorizontal,
    .flexWrap = A_SStackLayoutFlexWrapWrap,
    .alignContent = A_SStackLayoutAlignContentStart,
    .lineSpacing = 5,
  };

  CGSize subnodeSize = {50, 50};
  NSArray<A_SDisplayNode *> *subnodes = @[
                                         // 1st line
                                         A_SDisplayNodeWithBackgroundColor([UIColor redColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor yellowColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor blueColor], subnodeSize),
                                         // 2nd line
                                         A_SDisplayNodeWithBackgroundColor([UIColor magentaColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor greenColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor cyanColor], subnodeSize),
                                         // 3rd line
                                         A_SDisplayNodeWithBackgroundColor([UIColor brownColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor orangeColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor purpleColor], subnodeSize),
                                         ];

  for (A_SDisplayNode *subnode in subnodes) {
    subnode.style.spacingBefore = 5;
    subnode.style.spacingAfter = 5;
  }

  // 3 lines, each line has 3 items, each item has a size of {50, 50}
  // width is 190px, enough to fit 3 items into a line
  // Test that interitem spacing is reset on new lines. Otherwise, lines after the 1st line would have only 2 items.
  // See: https://github.com/Tex_tureGroup/Tex_ture/pull/472
  static A_SSizeRange kSize = {{190, 300}, {190, 300}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

#pragma mark - Content alignment tests

- (void)testAlignContentUnderflow
{
  // 3 lines, each line has 2 items, each item has a size of {50, 50}
  // width is 110px. It's 10px bigger than the required width of each line (110px vs 100px) to test that items are still correctly collected into lines
  static A_SSizeRange kSize = {{110, 300}, {110, 300}};
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentStart sizeRange:kSize identifier:@"alignContentStart"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentCenter sizeRange:kSize identifier:@"alignContentCenter"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentEnd sizeRange:kSize identifier:@"alignContentEnd"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentSpaceBetween sizeRange:kSize identifier:@"alignContentSpaceBetween"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentSpaceAround sizeRange:kSize identifier:@"alignContentSpaceAround"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentStretch sizeRange:kSize identifier:@"alignContentStretch"];
}

- (void)testAlignContentOverflow
{
  // 6 lines, each line has 1 item, each item has a size of {50, 50}
  // width is 40px. It's 10px smaller than the width of each item (40px vs 50px) to test that items are still correctly collected into lines
  static A_SSizeRange kSize = {{40, 260}, {40, 260}};
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentStart sizeRange:kSize identifier:@"alignContentStart"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentCenter sizeRange:kSize identifier:@"alignContentCenter"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentEnd sizeRange:kSize identifier:@"alignContentEnd"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentSpaceBetween sizeRange:kSize identifier:@"alignContentSpaceBetween"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentSpaceAround sizeRange:kSize identifier:@"alignContentSpaceAround"];
}

- (void)testAlignContentWithUnconstrainedCrossSize
{
  // 3 lines, each line has 2 items, each item has a size of {50, 50}
  // width is 110px. It's 10px bigger than the required width of each line (110px vs 100px) to test that items are still correctly collected into lines
  // height is unconstrained. It causes no cross size violation and the end results are all similar to A_SStackLayoutAlignContentStart.
  static A_SSizeRange kSize = {{110, 0}, {110, CGFLOAT_MAX}};
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentStart sizeRange:kSize identifier:nil];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentCenter sizeRange:kSize identifier:nil];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentEnd sizeRange:kSize identifier:nil];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentSpaceBetween sizeRange:kSize identifier:nil];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentSpaceAround sizeRange:kSize identifier:nil];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentStretch sizeRange:kSize identifier:nil];
}

- (void)testAlignContentStretchAndOtherAlignments
{
  A_SStackLayoutSpecStyle style = {
    .direction = A_SStackLayoutDirectionHorizontal,
    .flexWrap = A_SStackLayoutFlexWrapWrap,
    .alignContent = A_SStackLayoutAlignContentStretch,
    .alignItems = A_SStackLayoutAlignItemsStart,
  };
  
  CGSize subnodeSize = {50, 50};
  NSArray<A_SDisplayNode *> *subnodes = @[
                                         // 1st line
                                         A_SDisplayNodeWithBackgroundColor([UIColor redColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor yellowColor], subnodeSize),
                                         // 2nd line
                                         A_SDisplayNodeWithBackgroundColor([UIColor blueColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor magentaColor], subnodeSize),
                                         // 3rd line
                                         A_SDisplayNodeWithBackgroundColor([UIColor greenColor], subnodeSize),
                                         A_SDisplayNodeWithBackgroundColor([UIColor cyanColor], subnodeSize),
                                         ];
  
  subnodes[1].style.alignSelf = A_SStackLayoutAlignSelfStart;
  subnodes[3].style.alignSelf = A_SStackLayoutAlignSelfCenter;
  subnodes[5].style.alignSelf = A_SStackLayoutAlignSelfEnd;
  
  // 3 lines, each line has 2 items, each item has a size of {50, 50}
  // width is 110px. It's 10px bigger than the required width of each line (110px vs 100px) to test that items are still correctly collected into lines
  static A_SSizeRange kSize = {{110, 300}, {110, 300}};
  [self testStackLayoutSpecWithStyle:style sizeRange:kSize subnodes:subnodes identifier:nil];
}

#pragma mark - Line spacing tests

- (void)testAlignContentAndLineSpacingUnderflow
{
  // 3 lines, each line has 2 items, each item has a size of {50, 50}
  // 10px between lines
  // width is 110px. It's 10px bigger than the required width of each line (110px vs 100px) to test that items are still correctly collected into lines
  static A_SSizeRange kSize = {{110, 320}, {110, 320}};
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentStart lineSpacing:10 sizeRange:kSize identifier:@"alignContentStart"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentCenter lineSpacing:10 sizeRange:kSize identifier:@"alignContentCenter"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentEnd lineSpacing:10 sizeRange:kSize identifier:@"alignContentEnd"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentSpaceBetween lineSpacing:10 sizeRange:kSize identifier:@"alignContentSpaceBetween"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentSpaceAround lineSpacing:10 sizeRange:kSize identifier:@"alignContentSpaceAround"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentStretch lineSpacing:10 sizeRange:kSize identifier:@"alignContentStretch"];
}

- (void)testAlignContentAndLineSpacingOverflow
{
  // 6 lines, each line has 1 item, each item has a size of {50, 50}
  // 10px between lines
  // width is 40px. It's 10px smaller than the width of each item (40px vs 50px) to test that items are still correctly collected into lines
  static A_SSizeRange kSize = {{40, 310}, {40, 310}};
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentStart lineSpacing:10 sizeRange:kSize identifier:@"alignContentStart"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentCenter lineSpacing:10 sizeRange:kSize identifier:@"alignContentCenter"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentEnd lineSpacing:10 sizeRange:kSize identifier:@"alignContentEnd"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentSpaceBetween lineSpacing:10 sizeRange:kSize identifier:@"alignContentSpaceBetween"];
  [self testStackLayoutSpecWithAlignContent:A_SStackLayoutAlignContentSpaceAround lineSpacing:10 sizeRange:kSize identifier:@"alignContentSpaceAround"];
}

@end
