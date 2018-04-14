//
//  A_SCellNode.mm
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

#import <Async_DisplayKit/A_SCellNode+Internal.h>

#import <Async_DisplayKit/A_SEqualityHelpers.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SCollectionView+Undeprecated.h>
#import <Async_DisplayKit/A_SCollectionElement.h>
#import <Async_DisplayKit/A_STableView+Undeprecated.h>
#import <Async_DisplayKit/_A_SDisplayView.h>
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>
#import <Async_DisplayKit/A_STextNode.h>
#import <Async_DisplayKit/A_SCollectionNode.h>
#import <Async_DisplayKit/A_STableNode.h>

#import <Async_DisplayKit/A_SViewController.h>
#import <Async_DisplayKit/A_SInsetLayoutSpec.h>
#import <Async_DisplayKit/A_SDisplayNodeInternal.h>

#pragma mark -
#pragma mark A_SCellNode

@interface A_SCellNode ()
{
  A_SDisplayNodeViewControllerBlock _viewControllerBlock;
  A_SDisplayNodeDidLoadBlock _viewControllerDidLoadBlock;
  A_SDisplayNode *_viewControllerNode;
  UIViewController *_viewController;
  BOOL _suspendInteractionDelegate;
}

@end

@implementation A_SCellNode
@synthesize interactionDelegate = _interactionDelegate;

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;

  // Use UITableViewCell defaults
  _selectionStyle = UITableViewCellSelectionStyleDefault;
  self.clipsToBounds = YES;

  return self;
}

- (instancetype)initWithViewControllerBlock:(A_SDisplayNodeViewControllerBlock)viewControllerBlock didLoadBlock:(A_SDisplayNodeDidLoadBlock)didLoadBlock
{
  if (!(self = [super init]))
    return nil;
  
  A_SDisplayNodeAssertNotNil(viewControllerBlock, @"should initialize with a valid block that returns a UIViewController");
  _viewControllerBlock = viewControllerBlock;
  _viewControllerDidLoadBlock = didLoadBlock;

  return self;
}

- (void)didLoad
{
  [super didLoad];

  if (_viewControllerBlock != nil) {

    _viewController = _viewControllerBlock();
    _viewControllerBlock = nil;

    if ([_viewController isKindOfClass:[A_SViewController class]]) {
      A_SViewController *asViewController = (A_SViewController *)_viewController;
      _viewControllerNode = asViewController.node;
      [_viewController view];
    } else {
      // Careful to avoid retain cycle
      UIViewController *viewController = _viewController;
      _viewControllerNode = [[A_SDisplayNode alloc] initWithViewBlock:^{
        return viewController.view;
      }];
    }
    [self addSubnode:_viewControllerNode];

    // Since we just loaded our node, and added _viewControllerNode as a subnode,
    // _viewControllerNode must have just loaded its view, so now is an appropriate
    // time to execute our didLoadBlock, if we were given one.
    if (_viewControllerDidLoadBlock != nil) {
      _viewControllerDidLoadBlock(self);
      _viewControllerDidLoadBlock = nil;
    }
  }
}

- (void)layout
{
  [super layout];
  
  _viewControllerNode.frame = self.bounds;
}

- (void)_rootNodeDidInvalidateSize
{
  if (_interactionDelegate != nil) {
    [_interactionDelegate nodeDidInvalidateSize:self];
  } else {
    [super _rootNodeDidInvalidateSize];
  }
}

- (void)_layoutTransitionMeasurementDidFinish
{
  if (_interactionDelegate != nil) {
    [_interactionDelegate nodeDidInvalidateSize:self];
  } else {
    [super _layoutTransitionMeasurementDidFinish];
  }
}

- (void)setSelected:(BOOL)selected
{
  if (_selected != selected) {
    _selected = selected;
    if (!_suspendInteractionDelegate) {
      [_interactionDelegate nodeSelectedStateDidChange:self];
    }
  }
}

- (void)setHighlighted:(BOOL)highlighted
{
  if (_highlighted != highlighted) {
    _highlighted = highlighted;
    if (!_suspendInteractionDelegate) {
      [_interactionDelegate nodeHighlightedStateDidChange:self];
    }
  }
}

- (void)__setSelectedFromUIKit:(BOOL)selected;
{
  if (selected != _selected) {
    _suspendInteractionDelegate = YES;
    self.selected = selected;
    _suspendInteractionDelegate = NO;
  }
}

- (void)__setHighlightedFromUIKit:(BOOL)highlighted;
{
  if (highlighted != _highlighted) {
    _suspendInteractionDelegate = YES;
    self.highlighted = highlighted;
    _suspendInteractionDelegate = NO;
  }
}

- (BOOL)canUpdateToNodeModel:(id)nodeModel
{
  return [self.nodeModel class] == [nodeModel class];
}

- (NSIndexPath *)indexPath
{
  return [self.owningNode indexPathForNode:self];
}

- (UIViewController *)viewController
{
  A_SDisplayNodeAssertMainThread();
  // Force the view to load so that we will create the
  // view controller if we haven't already.
  if (self.isNodeLoaded == NO) {
    [self view];
  }
  return _viewController;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssert([self.view isKindOfClass:_A_SDisplayView.class], @"A_SCellNode views must be of type _A_SDisplayView");
  [(_A_SDisplayView *)self.view __forwardTouchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssert([self.view isKindOfClass:_A_SDisplayView.class], @"A_SCellNode views must be of type _A_SDisplayView");
  [(_A_SDisplayView *)self.view __forwardTouchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssert([self.view isKindOfClass:_A_SDisplayView.class], @"A_SCellNode views must be of type _A_SDisplayView");
  [(_A_SDisplayView *)self.view __forwardTouchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssert([self.view isKindOfClass:_A_SDisplayView.class], @"A_SCellNode views must be of type _A_SDisplayView");
  [(_A_SDisplayView *)self.view __forwardTouchesCancelled:touches withEvent:event];
}

#pragma clang diagnostic pop

- (void)setLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
  A_SDisplayNodeAssertMainThread();
  if (A_SObjectIsEqual(layoutAttributes, _layoutAttributes) == NO) {
    _layoutAttributes = layoutAttributes;
    if (layoutAttributes != nil) {
      [self applyLayoutAttributes:layoutAttributes];
    }
  }
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
  // To be overriden by subclasses
}

- (void)cellNodeVisibilityEvent:(A_SCellNodeVisibilityEvent)event inScrollView:(UIScrollView *)scrollView withCellFrame:(CGRect)cellFrame
{
  // To be overriden by subclasses
}

- (void)didEnterVisibleState
{
  [super didEnterVisibleState];
  if (self.neverShowPlaceholders) {
    [self recursivelyEnsureDisplaySynchronously:YES];
  }
  [self handleVisibilityChange:YES];
}

- (void)didExitVisibleState
{
  [super didExitVisibleState];
  [self handleVisibilityChange:NO];
}

+ (BOOL)requestsVisibilityNotifications
{
  static NSCache<Class, NSNumber *> *cache;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [[NSCache alloc] init];
  });
  NSNumber *result = [cache objectForKey:self];
  if (result == nil) {
    BOOL overrides = A_SSubclassOverridesSelector([A_SCellNode class], self, @selector(cellNodeVisibilityEvent:inScrollView:withCellFrame:));
    result = overrides ? (NSNumber *)kCFBooleanTrue : (NSNumber *)kCFBooleanFalse;
    [cache setObject:result forKey:self];
  }
  return (result == (NSNumber *)kCFBooleanTrue);
}

- (void)handleVisibilityChange:(BOOL)isVisible
{
  if ([self.class requestsVisibilityNotifications] == NO) {
    return; // The work below is expensive, and only valuable for subclasses watching visibility events.
  }
  
  // NOTE: This assertion is failing in some apps and will be enabled soon.
  // A_SDisplayNodeAssert(self.isNodeLoaded, @"Node should be loaded in order for it to become visible or invisible.  If not in this situation, we shouldn't trigger creating the view.");
  
  UIView *view = self.view;
  CGRect cellFrame = CGRectZero;
  
  // Ensure our _scrollView is still valid before converting.  It's also possible that we have already been removed from the _scrollView,
  // in which case it is not valid to perform a convertRect (this actually crashes on iOS 8).
  UIScrollView *scrollView = (_scrollView != nil && view.superview != nil && [view isDescendantOfView:_scrollView]) ? _scrollView : nil;
  if (scrollView) {
    cellFrame = [view convertRect:view.bounds toView:_scrollView];
  }
  
  // If we did not convert, we'll pass along CGRectZero and a nil scrollView.  The EventInvisible call is thus equivalent to
  // didExitVisibileState, but is more convenient for the developer than implementing multiple methods.
  [self cellNodeVisibilityEvent:isVisible ? A_SCellNodeVisibilityEventVisible
                                          : A_SCellNodeVisibilityEventInvisible
                   inScrollView:scrollView
                  withCellFrame:cellFrame];
}

- (NSMutableArray<NSDictionary *> *)propertiesForDebugDescription
{
  NSMutableArray *result = [super propertiesForDebugDescription];
  
  UIScrollView *scrollView = self.scrollView;
  
  A_SDisplayNode *owningNode = scrollView.asyncdisplaykit_node;
  if ([owningNode isKindOfClass:[A_SCollectionNode class]]) {
    NSIndexPath *ip = [(A_SCollectionNode *)owningNode indexPathForNode:self];
    if (ip != nil) {
      [result addObject:@{ @"indexPath" : ip }];
    }
    [result addObject:@{ @"collectionNode" : owningNode }];
  } else if ([owningNode isKindOfClass:[A_STableNode class]]) {
    NSIndexPath *ip = [(A_STableNode *)owningNode indexPathForNode:self];
    if (ip != nil) {
      [result addObject:@{ @"indexPath" : ip }];
    }
    [result addObject:@{ @"tableNode" : owningNode }];
  
  } else if ([scrollView isKindOfClass:[A_SCollectionView class]]) {
    NSIndexPath *ip = [(A_SCollectionView *)scrollView indexPathForNode:self];
    if (ip != nil) {
      [result addObject:@{ @"indexPath" : ip }];
    }
    [result addObject:@{ @"collectionView" : A_SObjectDescriptionMakeTiny(scrollView) }];
    
  } else if ([scrollView isKindOfClass:[A_STableView class]]) {
    NSIndexPath *ip = [(A_STableView *)scrollView indexPathForNode:self];
    if (ip != nil) {
      [result addObject:@{ @"indexPath" : ip }];
    }
    [result addObject:@{ @"tableView" : A_SObjectDescriptionMakeTiny(scrollView) }];
  }

  return result;
}

- (NSString *)supplementaryElementKind
{
  return self.collectionElement.supplementaryElementKind;
}

- (BOOL)supportsLayerBacking
{
  return NO;
}

@end


#pragma mark -
#pragma mark A_STextCellNode

@implementation A_STextCellNode

static const CGFloat kA_STextCellNodeDefaultFontSize = 18.0f;
static const CGFloat kA_STextCellNodeDefaultHorizontalPadding = 15.0f;
static const CGFloat kA_STextCellNodeDefaultVerticalPadding = 11.0f;

- (instancetype)init
{
  return [self initWithAttributes:[A_STextCellNode defaultTextAttributes] insets:[A_STextCellNode defaultTextInsets]];
}

- (instancetype)initWithAttributes:(NSDictionary *)textAttributes insets:(UIEdgeInsets)textInsets
{
  self = [super init];
  if (self) {
    _textInsets = textInsets;
    _textAttributes = [textAttributes copy];
    _textNode = [[A_STextNode alloc] init];
    self.automaticallyManagesSubnodes = YES;
  }
  return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:self.textInsets child:self.textNode];
}

+ (NSDictionary *)defaultTextAttributes
{
  return @{NSFontAttributeName : [UIFont systemFontOfSize:kA_STextCellNodeDefaultFontSize]};
}

+ (UIEdgeInsets)defaultTextInsets
{
    return UIEdgeInsetsMake(kA_STextCellNodeDefaultVerticalPadding, kA_STextCellNodeDefaultHorizontalPadding, kA_STextCellNodeDefaultVerticalPadding, kA_STextCellNodeDefaultHorizontalPadding);
}

- (void)setTextAttributes:(NSDictionary *)textAttributes
{
  A_SDisplayNodeAssertNotNil(textAttributes, @"Invalid text attributes");
  
  _textAttributes = [textAttributes copy];
  
  [self updateAttributedText];
}

- (void)setTextInsets:(UIEdgeInsets)textInsets
{
  _textInsets = textInsets;

  [self setNeedsLayout];
}

- (void)setText:(NSString *)text
{
  if (A_SObjectIsEqual(_text, text)) return;

  _text = [text copy];
  
  [self updateAttributedText];
}

- (void)updateAttributedText
{
  if (_text == nil) {
    _textNode.attributedText = nil;
    return;
  }
  
  _textNode.attributedText = [[NSAttributedString alloc] initWithString:self.text attributes:self.textAttributes];
  [self setNeedsLayout];
}

@end
