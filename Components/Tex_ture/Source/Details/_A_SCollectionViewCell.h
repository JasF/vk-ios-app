//
//  _A_SCollectionViewCell.h
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

#import <UIKit/UIKit.h>
#import <Async_DisplayKit/A_SBaseDefines.h>
#import <Async_DisplayKit/A_SCellNode.h>

@class A_SCollectionElement;

NS_ASSUME_NONNULL_BEGIN

A_S_SUBCLASSING_RESTRICTED // Note: A_SDynamicCastStrict is used on instances of this class based on this restriction.
@interface _A_SCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong, nullable) A_SCollectionElement *element;
@property (nonatomic, strong, readonly, nullable) A_SCellNode *node;
@property (nonatomic, strong, nullable) UICollectionViewLayoutAttributes *layoutAttributes;

/**
 * Whether or not this cell is interested in cell node visibility events.
 * -cellNodeVisibilityEvent:inScrollView: should be called only if this property is YES.
 */
@property (nonatomic, readonly) BOOL consumesCellNodeVisibilityEvents;

- (void)cellNodeVisibilityEvent:(A_SCellNodeVisibilityEvent)event inScrollView:(UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END
