//
//  _A_SCollectionReusableView.m
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

#import "_A_SCollectionReusableView.h"
#import <Async_DisplayKit/A_SCellNode+Internal.h>
#import <Async_DisplayKit/A_SCollectionElement.h>

@implementation _A_SCollectionReusableView

- (A_SCellNode *)node
{
  return self.element.node;
}

- (void)setElement:(A_SCollectionElement *)element
{
  A_SDisplayNodeAssertMainThread();
  element.node.layoutAttributes = _layoutAttributes;
  _element = element;
}

- (void)setLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
  _layoutAttributes = layoutAttributes;
  self.node.layoutAttributes = layoutAttributes;
}

- (void)prepareForReuse
{
  self.layoutAttributes = nil;
  
  // Need to clear element before UIKit calls setSelected:NO / setHighlighted:NO on its cells
  self.element = nil;
  [super prepareForReuse];
}

/**
 * In the initial case, this is called by UICollectionView during cell dequeueing, before
 *   we get a chance to assign a node to it, so we must be sure to set these layout attributes
 *   on our node when one is next assigned to us in @c setNode: . Since there may be cases when we _do_ already
 *   have our node assigned e.g. during a layout update for existing cells, we also attempt
 *   to update it now.
 */
- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
  self.layoutAttributes = layoutAttributes;
}

/**
 * Keep our node filling our content view.
 */
- (void)layoutSubviews
{
  [super layoutSubviews];
  self.node.frame = self.bounds;
}

@end

/**
 * A category that makes _A_SCollectionReusableView conform to IGListBindable.
 *
 * We don't need to do anything to bind the view model – the cell node
 * serves the same purpose.
 */
#if __has_include(<IGListKit/IGListBindable.h>)

#import <IGListKit/IGListBindable.h>

@interface _A_SCollectionReusableView (IGListBindable) <IGListBindable>
@end

@implementation _A_SCollectionReusableView (IGListBindable)

- (void)bindViewModel:(id)viewModel
{
  // nop
}

@end

#endif
