//
//  A_SDisplayNode+Yoga.mm
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

#import <Async_DisplayKit/A_SAvailability.h>

#if YOGA /* YOGA */

#import <Async_DisplayKit/_A_SDisplayViewAccessiblity.h>
#import <Async_DisplayKit/A_SYogaLayoutSpec.h>
#import <Async_DisplayKit/A_SYogaUtilities.h>
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkSubclasses.h>
#import <Async_DisplayKit/A_SDisplayNodeInternal.h>
#import <Async_DisplayKit/A_SLayout.h>

#define YOGA_LAYOUT_LOGGING 0

#pragma mark - A_SDisplayNode+Yoga

@interface A_SDisplayNode (YogaInternal)
@property (nonatomic, weak) A_SDisplayNode *yogaParent;
- (A_SSizeRange)_locked_constrainedSizeForLayoutPass;
@end

@implementation A_SDisplayNode (Yoga)

- (void)setYogaChildren:(NSArray *)yogaChildren
{
  for (A_SDisplayNode *child in [_yogaChildren copy]) {
    // Make sure to un-associate the YGNodeRef tree before replacing _yogaChildren
    // If this becomes a performance bottleneck, it can be optimized by not doing the NSArray removals here.
    [self removeYogaChild:child];
  }
  _yogaChildren = nil;
  for (A_SDisplayNode *child in yogaChildren) {
    [self addYogaChild:child];
  }
}

- (NSArray *)yogaChildren
{
  return _yogaChildren;
}

- (void)addYogaChild:(A_SDisplayNode *)child
{
  [self insertYogaChild:child atIndex:_yogaChildren.count];
}

- (void)removeYogaChild:(A_SDisplayNode *)child
{
  if (child == nil) {
    return;
  }
  
  [_yogaChildren removeObjectIdenticalTo:child];

  // YGNodeRef removal is done in setParent:
  child.yogaParent = nil;
}

- (void)insertYogaChild:(A_SDisplayNode *)child atIndex:(NSUInteger)index
{
  if (child == nil) {
    return;
  }
  if (_yogaChildren == nil) {
    _yogaChildren = [NSMutableArray array];
  }

  // Clean up state in case this child had another parent.
  [self removeYogaChild:child];

  [_yogaChildren insertObject:child atIndex:index];

  // YGNodeRef insertion is done in setParent:
  child.yogaParent = self;
}

- (void)semanticContentAttributeDidChange:(UISemanticContentAttribute)attribute
{
  if (A_S_AT_LEA_ST_IOS9) {
    UIUserInterfaceLayoutDirection layoutDirection =
    [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:attribute];
    self.style.direction = (layoutDirection == UIUserInterfaceLayoutDirectionLeftToRight
                            ? YGDirectionLTR : YGDirectionRTL);
  }
}

- (void)setYogaParent:(A_SDisplayNode *)yogaParent
{
  if (_yogaParent == yogaParent) {
    return;
  }

  YGNodeRef yogaNode = [self.style yogaNodeCreateIfNeeded];
  YGNodeRef oldParentRef = YGNodeGetParent(yogaNode);
  if (oldParentRef != NULL) {
    YGNodeRemoveChild(oldParentRef, yogaNode);
  }

  _yogaParent = yogaParent;
  if (yogaParent) {
    YGNodeRef newParentRef = [yogaParent.style yogaNodeCreateIfNeeded];
    YGNodeInsertChild(newParentRef, yogaNode, YGNodeGetChildCount(newParentRef));
  }
}

- (A_SDisplayNode *)yogaParent
{
  return _yogaParent;
}

- (void)setYogaCalculatedLayout:(A_SLayout *)yogaCalculatedLayout
{
  _yogaCalculatedLayout = yogaCalculatedLayout;
}

- (A_SLayout *)yogaCalculatedLayout
{
  return _yogaCalculatedLayout;
}

- (void)setYogaLayoutInProgress:(BOOL)yogaLayoutInProgress
{
  setFlag(YogaLayoutInProgress, yogaLayoutInProgress);
  [self updateYogaMeasureFuncIfNeeded];
}

- (BOOL)yogaLayoutInProgress
{
  return checkFlag(YogaLayoutInProgress);
}

- (A_SLayout *)layoutForYogaNode
{
  YGNodeRef yogaNode = self.style.yogaNode;

  CGSize  size     = CGSizeMake(YGNodeLayoutGetWidth(yogaNode), YGNodeLayoutGetHeight(yogaNode));
  CGPoint position = CGPointMake(YGNodeLayoutGetLeft(yogaNode), YGNodeLayoutGetTop(yogaNode));

  return [A_SLayout layoutWithLayoutElement:self size:size position:position sublayouts:nil];
}

- (void)setupYogaCalculatedLayout
{
  YGNodeRef yogaNode = self.style.yogaNode;
  uint32_t childCount = YGNodeGetChildCount(yogaNode);
  A_SDisplayNodeAssert(childCount == self.yogaChildren.count,
                      @"Yoga tree should always be in sync with .yogaNodes array! %@", self.yogaChildren);

  NSMutableArray *sublayouts = [NSMutableArray arrayWithCapacity:childCount];
  for (A_SDisplayNode *subnode in self.yogaChildren) {
    [sublayouts addObject:[subnode layoutForYogaNode]];
  }

  // The layout for self should have position CGPointNull, but include the calculated size.
  CGSize size = CGSizeMake(YGNodeLayoutGetWidth(yogaNode), YGNodeLayoutGetHeight(yogaNode));
  A_SLayout *layout = [A_SLayout layoutWithLayoutElement:self size:size sublayouts:sublayouts];

#if A_SDISPLAYNODE_A_SSERTIONS_ENABLED
  // Assert that the sublayout is already flattened.
  for (A_SLayout *sublayout in layout.sublayouts) {
    if (sublayout.sublayouts.count > 0 || A_SDynamicCast(sublayout.layoutElement, A_SDisplayNode) == nil) {
      A_SDisplayNodeAssert(NO, @"Yoga sublayout is not flattened! %@, %@", self, sublayout);
    }
  }
#endif

  // Because this layout won't go through the rest of the logic in calculateLayoutThatFits:, flatten it now.
  layout = [layout filteredNodeLayoutTree];

  if ([self.yogaCalculatedLayout isEqual:layout] == NO) {
    self.yogaCalculatedLayout = layout;
  } else {
    layout = self.yogaCalculatedLayout;
    A_SYogaLog("-setupYogaCalculatedLayout: applying identical A_SLayout: %@", layout);
  }

  // Setup _pendingDisplayNodeLayout to reference the Yoga-calculated A_SLayout, *unless* we are a leaf node.
  // Leaf yoga nodes may have their own .sublayouts, if they use a layout spec (such as A_SButtonNode).
  // Their _pending variable is set after passing the Yoga checks at the start of -calculateLayoutThatFits:

  // For other Yoga nodes, there is no code that will set _pending unless we do it here. Why does it need to be set?
  // When CALayer triggers the -[A_SDisplayNode __layout] call, we will check if our current _pending layout
  // has a size which matches our current bounds size. If it does, that layout will be used without recomputing it.

  // NOTE: Yoga does not make the constrainedSize available to intermediate nodes in the tree (e.g. not root or leaves).
  // Although the size range provided here is not accurate, this will only affect caching of calls to layoutThatFits:
  // These calls will behave as if they are not cached, starting a new Yoga layout pass, but this will tap into Yoga's
  // own internal cache.

  if ([self shouldHaveYogaMeasureFunc] == NO) {
    YGNodeRef parentNode = YGNodeGetParent(yogaNode);
    CGSize parentSize = CGSizeZero;
    if (parentNode) {
      parentSize.width = YGNodeLayoutGetWidth(parentNode);
      parentSize.height = YGNodeLayoutGetHeight(parentNode);
    }
    _pendingDisplayNodeLayout = std::make_shared<A_SDisplayNodeLayout>(layout, A_SSizeRangeUnconstrained, parentSize, 0);
  }
}

- (BOOL)shouldHaveYogaMeasureFunc
{
  // Size calculation via calculateSizeThatFits: or layoutSpecThatFits:
  // This will be used for A_STextNode, as well as any other node that has no Yoga children
  BOOL isLeafNode = (self.yogaChildren.count == 0);
  BOOL definesCustomLayout = [self implementsLayoutMethod];
  return (isLeafNode && definesCustomLayout);
}

- (void)updateYogaMeasureFuncIfNeeded
{
  // We set the measure func only during layout. Otherwise, a cycle is created:
  // The YGNodeRef Context will retain the A_SDisplayNode, which retains the style, which owns the YGNodeRef.
  BOOL shouldHaveMeasureFunc = ([self shouldHaveYogaMeasureFunc] && checkFlag(YogaLayoutInProgress));

  A_SLayoutElementYogaUpdateMeasureFunc(self.style.yogaNode, shouldHaveMeasureFunc ? self : nil);
}

- (void)invalidateCalculatedYogaLayout
{
  YGNodeRef yogaNode = self.style.yogaNode;
  if (yogaNode && YGNodeGetMeasureFunc(yogaNode)) {
    // Yoga internally asserts that MarkDirty() may only be called on nodes with a measurement function.
    YGNodeMarkDirty(yogaNode);
  }
  self.yogaCalculatedLayout = nil;
}

- (void)calculateLayoutFromYogaRoot:(A_SSizeRange)rootConstrainedSize
{
  A_SDisplayNode *yogaParent = self.yogaParent;

  if (yogaParent) {
    A_SYogaLog("ESCALATING to Yoga root: %@", self);
    // TODO(appleguy): Consider how to get the constrainedSize for the yogaRoot when escalating manually.
    [yogaParent calculateLayoutFromYogaRoot:A_SSizeRangeUnconstrained];
    return;
  }

  A_SDN::MutexLocker l(__instanceLock__);

  // Prepare all children for the layout pass with the current Yoga tree configuration.
  A_SDisplayNodePerformBlockOnEveryYogaChild(self, ^(A_SDisplayNode * _Nonnull node) {
    node.yogaLayoutInProgress = YES;
  });

  if (A_SSizeRangeEqualToSizeRange(rootConstrainedSize, A_SSizeRangeUnconstrained)) {
    rootConstrainedSize = [self _locked_constrainedSizeForLayoutPass];
  }

  A_SYogaLog("CALCULATING at Yoga root with constraint = {%@, %@}: %@",
            NSStringFromCGSize(rootConstrainedSize.min), NSStringFromCGSize(rootConstrainedSize.max), self);

  YGNodeRef rootYogaNode = self.style.yogaNode;

  // Apply the constrainedSize as a base, known frame of reference.
  // If the root node also has style.*Size set, these will be overridden below.
  // YGNodeCalculateLayout currently doesn't offer the ability to pass a minimum size (max is passed there).

  // TODO(appleguy): Reconcile the self.style.*Size properties with rootConstrainedSize
  YGNodeStyleSetMinWidth (rootYogaNode, yogaFloatForCGFloat(rootConstrainedSize.min.width));
  YGNodeStyleSetMinHeight(rootYogaNode, yogaFloatForCGFloat(rootConstrainedSize.min.height));

  // It is crucial to use yogaFloat... to convert CGFLOAT_MAX into YGUndefined here.
  YGNodeCalculateLayout(rootYogaNode,
                        yogaFloatForCGFloat(rootConstrainedSize.max.width),
                        yogaFloatForCGFloat(rootConstrainedSize.max.height),
                        YGDirectionInherit);

  // Reset accessible elements, since layout may have changed.
  A_SPerformBlockOnMainThread(^{
    [(_A_SDisplayView *)self.view setAccessibleElements:nil];
  });

  A_SDisplayNodePerformBlockOnEveryYogaChild(self, ^(A_SDisplayNode * _Nonnull node) {
    [node setupYogaCalculatedLayout];
    node.yogaLayoutInProgress = NO;
  });

#if YOGA_LAYOUT_LOGGING /* YOGA_LAYOUT_LOGGING */
  // Concurrent layouts will interleave the NSLog messages unless we serialize.
  // Use @synchornize rather than trampolining to the main thread so the tree state isn't changed.
  @synchronized ([A_SDisplayNode class]) {
    NSLog(@"****************************************************************************");
    NSLog(@"******************** STARTING YOGA -> A_SLAYOUT CREATION ********************");
    NSLog(@"****************************************************************************");
    A_SDisplayNodePerformBlockOnEveryYogaChild(self, ^(A_SDisplayNode * _Nonnull node) {
      NSLog(@" "); // Newline
      NSLog(@"node = %@", node);
      NSLog(@"style = %@", node.style);
      NSLog(@"layout = %@", node.yogaCalculatedLayout);
      YGNodePrint(node.yogaNode, (YGPrintOptions)(YGPrintOptionsStyle | YGPrintOptionsLayout));
    });
  }
#endif /* YOGA_LAYOUT_LOGGING */
}

@end

#endif /* YOGA */
