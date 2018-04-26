//
//  A_STextKitRenderer.h
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

#import <vector>

#import <UIKit/UIKit.h>

#import <Async_DisplayKit/A_STextKitAttributes.h>

@class A_STextKitContext;
@class A_STextKitShadower;
@class A_STextKitFontSizeAdjuster;
@protocol A_STextKitTruncating;

/**
 A_STextKitRenderer is a modular object that is responsible for laying out and drawing text.

 A renderer will hold onto the TextKit layouts for the given attributes after initialization.  This may constitute a
 large amount of memory for large enough applications, so care must be taken when keeping many of these around in-memory
 at once.

 This object is designed to be modular and simple.  All complex maintenance of state should occur in sub-objects or be
 derived via pure functions or categories.  No touch-related handling belongs in this class.

 ALL sizing and layout information from this class is in the external coordinate space of the TextKit components.  This
 is an important distinction because all internal sizing and layout operations are carried out within the shadowed
 coordinate space.  Padding will be added for you in order to ensure clipping does not occur, and additional information
 on this transform is available via the shadower should you need it.
 */
@interface A_STextKitRenderer : NSObject

/**
 Designated Initializer
 @discussion Sizing will occur as a result of initialization, so be careful when/where you use this.
 */
- (instancetype)initWithTextKitAttributes:(const A_STextKitAttributes &)textComponentAttributes
                          constrainedSize:(const CGSize)constrainedSize;

@property (nonatomic, strong, readonly) A_STextKitContext *context;

@property (nonatomic, strong, readonly) id<A_STextKitTruncating> truncater;

@property (nonatomic, strong, readonly) A_STextKitFontSizeAdjuster *fontSizeAdjuster;

@property (nonatomic, strong, readonly) A_STextKitShadower *shadower;

@property (nonatomic, assign, readonly) A_STextKitAttributes attributes;

@property (nonatomic, assign, readonly) CGSize constrainedSize;

@property (nonatomic, assign, readonly) CGFloat currentScaleFactor;

#pragma mark - Drawing
/**
 Draw the renderer's text content into the bounds provided.

 @param bounds The rect in which to draw the contents of the renderer.
 */
- (void)drawInContext:(CGContextRef)context bounds:(CGRect)bounds;

#pragma mark - Layout

/**
 Returns the computed size of the renderer given the constrained size and other parameters in the initializer.
 */
- (CGSize)size;

#pragma mark - Text Ranges

/**
 The character range from the original attributedString that is displayed by the renderer given the parameters in the
 initializer.
 */
@property (nonatomic, assign, readonly) std::vector<NSRange> visibleRanges;

/**
 The number of lines shown in the string.
 */
- (NSUInteger)lineCount;

/**
 Whether or not the text is truncated.
 */
- (BOOL)isTruncated;

@end

@interface A_STextKitRenderer (A_STextKitRendererConvenience)

/**
 Returns the first visible range or an NSRange with location of NSNotFound and size of 0 if no first visible
 range exists
 */
@property (nonatomic, assign, readonly) NSRange firstVisibleRange;

@end
