//
//  A_SButtonNode.h
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

#import <Async_DisplayKit/A_SControlNode.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class A_SImageNode, A_STextNode;

/**
 Image alignment defines where the image will be placed relative to the text.
 */
typedef NS_ENUM(NSInteger, A_SButtonNodeImageAlignment) {
  /** Places the image before the text. */
  A_SButtonNodeImageAlignmentBeginning,
  /** Places the image after the text. */
  A_SButtonNodeImageAlignmentEnd
};

@interface A_SButtonNode : A_SControlNode

@property (nonatomic, readonly) A_STextNode  * titleNode;
@property (nonatomic, readonly) A_SImageNode * imageNode;
@property (nonatomic, readonly) A_SImageNode * backgroundImageNode;

/**
 Spacing between image and title. Defaults to 8.0.
 */
@property (nonatomic, assign) CGFloat contentSpacing;

/**
 Whether button should be laid out vertically (image on top of text) or horizontally (image to the left of text).
 A_SButton node does not yet support RTL but it should be fairly easy to implement.
 Defaults to YES.
 */
@property (nonatomic, assign) BOOL laysOutHorizontally;

/** Horizontally align content (text or image).
 Defaults to A_SHorizontalAlignmentMiddle.
 */
@property (nonatomic, assign) A_SHorizontalAlignment contentHorizontalAlignment;

/** Vertically align content (text or image).
 Defaults to A_SVerticalAlignmentCenter.
 */
@property (nonatomic, assign) A_SVerticalAlignment contentVerticalAlignment;

/**
 * @discussion The insets used around the title and image node
 */
@property (nonatomic, assign) UIEdgeInsets contentEdgeInsets;

/**
 * @discusstion Whether the image should be aligned at the beginning or at the end of node. Default is `A_SButtonNodeImageAlignmentBeginning`.
 */
@property (nonatomic, assign) A_SButtonNodeImageAlignment imageAlignment;

/**
 *  Returns the styled title associated with the specified state.
 *
 *  @param state The control state that uses the styled title.
 *
 *  @return The title for the specified state.
 */
- (nullable NSAttributedString *)attributedTitleForState:(UIControlState)state A_S_WARN_UNUSED_RESULT;

/**
 *  Sets the styled title to use for the specified state. This will reset styled title previously set with -setTitle:withFont:withColor:forState.
 *
 *  @param title The styled text string to use for the title.
 *  @param state The control state that uses the specified title.
 */
- (void)setAttributedTitle:(nullable NSAttributedString *)title forState:(UIControlState)state;

#if TARGET_OS_IOS
/**
 *  Sets the title to use for the specified state. This will reset styled title previously set with -setAttributedTitle:forState.
 *
 *  @param title The styled text string to use for the title.
 *  @param font The font to use for the title.
 *  @param color The color to use for the title.
 *  @param state The control state that uses the specified title.
 */
- (void)setTitle:(NSString *)title withFont:(nullable UIFont *)font withColor:(nullable UIColor *)color forState:(UIControlState)state;
#endif
/**
 *  Returns the image used for a button state.
 *
 *  @param state The control state that uses the image.
 *
 *  @return The image used for the specified state.
 */
- (nullable UIImage *)imageForState:(UIControlState)state A_S_WARN_UNUSED_RESULT;

/**
 *  Sets the image to use for the specified state.
 *
 *  @param image The image to use for the specified state.
 *  @param state The control state that uses the specified title.
 */
- (void)setImage:(nullable UIImage *)image forState:(UIControlState)state;

/**
 *  Sets the background image to use for the specified state.
 *
 *  @param image The image to use for the specified state.
 *  @param state The control state that uses the specified title.
 */
- (void)setBackgroundImage:(nullable UIImage *)image forState:(UIControlState)state;


/**
 *  Returns the background image used for a button state.
 *
 *  @param state The control state that uses the image.
 *
 *  @return The background image used for the specified state.
 */
- (nullable UIImage *)backgroundImageForState:(UIControlState)state A_S_WARN_UNUSED_RESULT;

@end

NS_ASSUME_NONNULL_END
