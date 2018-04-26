//
//  _A_SDisplayViewAccessiblity.mm
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

#ifndef A_SDK_ACCESSIBILITY_DISABLE

#import <Async_DisplayKit/_A_SDisplayView.h>
#import <Async_DisplayKit/A_SAvailability.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>
#import <Async_DisplayKit/A_SDisplayNodeInternal.h>

#import <queue>

NS_INLINE UIAccessibilityTraits InteractiveAccessibilityTraitsMask() {
  return UIAccessibilityTraitLink | UIAccessibilityTraitKeyboardKey | UIAccessibilityTraitButton;
}

#pragma mark - UIAccessibilityElement

@protocol A_SAccessibilityElementPositioning

@property (nonatomic, readonly) CGRect accessibilityFrame;

@end

typedef NSComparisonResult (^SortAccessibilityElementsComparator)(id<A_SAccessibilityElementPositioning>, id<A_SAccessibilityElementPositioning>);

/// Sort accessiblity elements first by y and than by x origin.
static void SortAccessibilityElements(NSMutableArray *elements)
{
  A_SDisplayNodeCAssertNotNil(elements, @"Should pass in a NSMutableArray");
  
  static SortAccessibilityElementsComparator comparator = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      comparator = ^NSComparisonResult(id<A_SAccessibilityElementPositioning> a, id<A_SAccessibilityElementPositioning> b) {
        CGPoint originA = a.accessibilityFrame.origin;
        CGPoint originB = b.accessibilityFrame.origin;
        if (originA.y == originB.y) {
          if (originA.x == originB.x) {
            return NSOrderedSame;
          }
          return (originA.x < originB.x) ? NSOrderedAscending : NSOrderedDescending;
        }
        return (originA.y < originB.y) ? NSOrderedAscending : NSOrderedDescending;
      };
  });
  [elements sortUsingComparator:comparator];
}

@interface A_SAccessibilityElement : UIAccessibilityElement<A_SAccessibilityElementPositioning>

@property (nonatomic, strong) A_SDisplayNode *node;
@property (nonatomic, strong) A_SDisplayNode *containerNode;

+ (A_SAccessibilityElement *)accessibilityElementWithContainer:(UIView *)container node:(A_SDisplayNode *)node containerNode:(A_SDisplayNode *)containerNode;

@end

@implementation A_SAccessibilityElement

+ (A_SAccessibilityElement *)accessibilityElementWithContainer:(UIView *)container node:(A_SDisplayNode *)node containerNode:(A_SDisplayNode *)containerNode
{
  A_SAccessibilityElement *accessibilityElement = [[A_SAccessibilityElement alloc] initWithAccessibilityContainer:container];
  accessibilityElement.node = node;
  accessibilityElement.containerNode = containerNode;
  accessibilityElement.accessibilityIdentifier = node.accessibilityIdentifier;
  accessibilityElement.accessibilityLabel = node.accessibilityLabel;
  accessibilityElement.accessibilityHint = node.accessibilityHint;
  accessibilityElement.accessibilityValue = node.accessibilityValue;
  accessibilityElement.accessibilityTraits = node.accessibilityTraits;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0
  if (A_S_AVAILABLE_IOS(11)) {
    accessibilityElement.accessibilityAttributedLabel = node.accessibilityAttributedLabel;
    accessibilityElement.accessibilityAttributedHint = node.accessibilityAttributedHint;
    accessibilityElement.accessibilityAttributedValue = node.accessibilityAttributedValue;
  }
#endif
  return accessibilityElement;
}

- (CGRect)accessibilityFrame
{
  CGRect accessibilityFrame = [self.containerNode convertRect:self.node.bounds fromNode:self.node];
  accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(accessibilityFrame, self.accessibilityContainer);
  return accessibilityFrame;
}

@end

#pragma mark - _A_SDisplayView / UIAccessibilityContainer

@interface A_SAccessibilityCustomAction : UIAccessibilityCustomAction<A_SAccessibilityElementPositioning>

@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) A_SDisplayNode *node;
@property (nonatomic, strong) A_SDisplayNode *containerNode;

@end

@implementation A_SAccessibilityCustomAction

- (CGRect)accessibilityFrame
{
  CGRect accessibilityFrame = [self.containerNode convertRect:self.node.bounds fromNode:self.node];
  accessibilityFrame = UIAccessibilityConvertFrameToScreenCoordinates(accessibilityFrame, self.container);
  return accessibilityFrame;
}

@end

/// Collect all subnodes for the given node by walking down the subnode tree and calculates the screen coordinates based on the containerNode and container
static void CollectUIAccessibilityElementsForNode(A_SDisplayNode *node, A_SDisplayNode *containerNode, id container, NSMutableArray *elements)
{
  A_SDisplayNodeCAssertNotNil(elements, @"Should pass in a NSMutableArray");
  
  A_SDisplayNodePerformBlockOnEveryNodeBFS(node, ^(A_SDisplayNode * _Nonnull currentNode) {
    // For every subnode that is layer backed or it's supernode has subtree rasterization enabled
    // we have to create a UIAccessibilityElement as no view for this node exists
    if (currentNode != containerNode && currentNode.isAccessibilityElement) {
      UIAccessibilityElement *accessibilityElement = [A_SAccessibilityElement accessibilityElementWithContainer:container node:currentNode containerNode:containerNode];
      [elements addObject:accessibilityElement];
    }
  });
}

static void CollectAccessibilityElementsForContainer(A_SDisplayNode *container, _A_SDisplayView *view, NSMutableArray *elements) {
  UIAccessibilityElement *accessiblityElement = [A_SAccessibilityElement accessibilityElementWithContainer:view node:container containerNode:container];

  NSMutableArray<A_SAccessibilityElement *> *labeledNodes = [NSMutableArray array];
  NSMutableArray<A_SAccessibilityCustomAction *> *actions = [NSMutableArray array];
  std::queue<A_SDisplayNode *> queue;
  queue.push(container);

  A_SDisplayNode *node;
  while (!queue.empty()) {
    node = queue.front();
    queue.pop();

    if (node != container && node.isAccessibilityContainer) {
      CollectAccessibilityElementsForContainer(node, view, elements);
      continue;
    }

    if (node.accessibilityLabel.length > 0) {
      if (node.accessibilityTraits & InteractiveAccessibilityTraitsMask()) {
        A_SAccessibilityCustomAction *action = [[A_SAccessibilityCustomAction alloc] initWithName:node.accessibilityLabel target:node selector:@selector(performAccessibilityCustomAction:)];
        action.node = node;
        action.containerNode = node.supernode;
        action.container = node.supernode.view;
        [actions addObject:action];
      } else {
        // Even though not surfaced to UIKit, create a non-interactive element for purposes of building sorted aggregated label.
        A_SAccessibilityElement *nonInteractiveElement = [A_SAccessibilityElement accessibilityElementWithContainer:view node:node containerNode:container];
        [labeledNodes addObject:nonInteractiveElement];
      }
    }

    for (A_SDisplayNode *subnode in node.subnodes) {
      queue.push(subnode);
    }
  }

  SortAccessibilityElements(labeledNodes);

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0
  if (A_S_AVAILABLE_IOS(11)) {
    NSArray *attributedLabels = [labeledNodes valueForKey:@"accessibilityAttributedLabel"];
    NSMutableAttributedString *attributedLabel = [NSMutableAttributedString new];
    [attributedLabels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
      if (idx != 0) {
        [attributedLabel appendAttributedString:[[NSAttributedString alloc] initWithString:@", "]];
      }
      [attributedLabel appendAttributedString:(NSAttributedString *)obj];
    }];
    accessiblityElement.accessibilityAttributedLabel = attributedLabel;
  } else
#endif
  {
    NSArray *labels = [labeledNodes valueForKey:@"accessibilityLabel"];
    accessiblityElement.accessibilityLabel = [labels componentsJoinedByString:@", "];
  }

  SortAccessibilityElements(actions);
  accessiblityElement.accessibilityCustomActions = actions;

  [elements addObject:accessiblityElement];
}

/// Collect all accessibliity elements for a given view and view node
static void CollectAccessibilityElementsForView(_A_SDisplayView *view, NSMutableArray *elements)
{
  A_SDisplayNodeCAssertNotNil(elements, @"Should pass in a NSMutableArray");
  
  A_SDisplayNode *node = view.asyncdisplaykit_node;

  if (node.isAccessibilityContainer) {
    CollectAccessibilityElementsForContainer(node, view, elements);
    return;
  }
  
  // Handle rasterize case
  if (node.rasterizesSubtree) {
    CollectUIAccessibilityElementsForNode(node, node, view, elements);
    return;
  }
  
  for (A_SDisplayNode *subnode in node.subnodes) {
    if (subnode.isAccessibilityElement) {
      
      // An accessiblityElement can either be a UIView or a UIAccessibilityElement
      if (subnode.isLayerBacked) {
        // No view for layer backed nodes exist. It's necessary to create a UIAccessibilityElement that represents this node
        UIAccessibilityElement *accessiblityElement = [A_SAccessibilityElement accessibilityElementWithContainer:view node:subnode containerNode:node];
        [elements addObject:accessiblityElement];
      } else {
        // Accessiblity element is not layer backed just add the view as accessibility element
        [elements addObject:subnode.view];
      }
    } else if (subnode.isLayerBacked) {
      // Go down the hierarchy of the layer backed subnode and collect all of the UIAccessibilityElement
      CollectUIAccessibilityElementsForNode(subnode, node, view, elements);
    } else if ([subnode accessibilityElementCount] > 0) {
      // UIView is itself a UIAccessibilityContainer just add it
      [elements addObject:subnode.view];
    }
  }
}

@interface _A_SDisplayView () {
  NSArray *_accessibleElements;
}

@end

@implementation _A_SDisplayView (UIAccessibilityContainer)

#pragma mark - UIAccessibility

- (void)setAccessibleElements:(NSArray *)accessibleElements
{
  _accessibleElements = nil;
}

- (NSArray *)accessibleElements
{
  A_SDisplayNode *viewNode = self.asyncdisplaykit_node;
  if (viewNode == nil) {
    return @[];
  }
  
  if (_accessibleElements != nil) {
    return _accessibleElements;
  }
  
  NSMutableArray *accessibleElements = [NSMutableArray array];
  CollectAccessibilityElementsForView(self, accessibleElements);
  SortAccessibilityElements(accessibleElements);
  _accessibleElements = accessibleElements;
  
  return _accessibleElements;
}

- (NSInteger)accessibilityElementCount
{
  return self.accessibleElements.count;
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
  return self.accessibleElements[index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
  return [self.accessibleElements indexOfObjectIdenticalTo:element];
}

@end

#endif
