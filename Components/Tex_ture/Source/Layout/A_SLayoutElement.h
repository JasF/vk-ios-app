//
//  A_SLayoutElement.h
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

#import <Async_DisplayKit/A_SLayoutElementPrivate.h>
#import <Async_DisplayKit/A_SLayoutElementExtensibility.h>
#import <Async_DisplayKit/A_SDimensionInternal.h>
#import <Async_DisplayKit/A_SStackLayoutElement.h>
#import <Async_DisplayKit/A_SAbsoluteLayoutElement.h>
#import <Async_DisplayKit/A_STraitCollection.h>
#import <Async_DisplayKit/A_SAsciiArtBoxCreator.h>

@class A_SLayout;
@class A_SLayoutSpec;
@protocol A_SLayoutElementStylability;

@protocol A_STraitEnvironment;

NS_ASSUME_NONNULL_BEGIN

/** A constant that indicates that the parent's size is not yet determined in a given dimension. */
extern CGFloat const A_SLayoutElementParentDimensionUndefined;

/** A constant that indicates that the parent's size is not yet determined in either dimension. */
extern CGSize const A_SLayoutElementParentSizeUndefined;

/** Type of A_SLayoutElement  */
typedef NS_ENUM(NSUInteger, A_SLayoutElementType) {
  A_SLayoutElementTypeLayoutSpec,
  A_SLayoutElementTypeDisplayNode
};

#pragma mark - A_SLayoutElement

/**
 * The A_SLayoutElement protocol declares a method for measuring the layout of an object. A layout
 * is defined by an A_SLayout return value, and must specify 1) the size (but not position) of the
 * layoutElement object, and 2) the size and position of all of its immediate child objects. The tree 
 * recursion is driven by parents requesting layouts from their children in order to determine their 
 * size, followed by the parents setting the position of the children once the size is known
 *
 * The protocol also implements a "family" of LayoutElement protocols. These protocols contain layout 
 * options that can be used for specific layout specs. For example, A_SStackLayoutSpec has options
 * defining how a layoutElement should shrink or grow based upon available space.
 *
 * These layout options are all stored in an A_SLayoutOptions class (that is defined in A_SLayoutElementPrivate).
 * Generally you needn't worry about the layout options class, as the layoutElement protocols allow all direct
 * access to the options via convenience properties. If you are creating custom layout spec, then you can
 * extend the backing layout options class to accommodate any new layout options.
 */
@protocol A_SLayoutElement <A_SLayoutElementExtensibility, A_STraitEnvironment, A_SLayoutElementAsciiArtProtocol>

#pragma mark - Getter

/**
 * @abstract Returns type of layoutElement
 */
@property (nonatomic, assign, readonly) A_SLayoutElementType layoutElementType;

/**
 * @abstract A size constraint that should apply to this A_SLayoutElement.
 */
@property (nonatomic, strong, readonly) A_SLayoutElementStyle *style;

/**
 * @abstract Returns all children of an object which class conforms to the A_SLayoutElement protocol
 */
- (nullable NSArray<id<A_SLayoutElement>> *)sublayoutElements;

#pragma mark - Calculate layout

/**
 * @abstract Asks the node to return a layout based on given size range.
 *
 * @param constrainedSize The minimum and maximum sizes the receiver should fit in.
 *
 * @return An A_SLayout instance defining the layout of the receiver (and its children, if the box layout model is used).
 *
 * @discussion Though this method does not set the bounds of the view, it does have side effects--caching both the
 * constraint and the result.
 *
 * @warning Subclasses must not override this; it caches results from -calculateLayoutThatFits:.  Calling this method may
 * be expensive if result is not cached.
 *
 * @see [A_SDisplayNode(Subclassing) calculateLayoutThatFits:]
 */
- (A_SLayout *)layoutThatFits:(A_SSizeRange)constrainedSize;

/**
 * Call this on children layoutElements to compute their layouts within your implementation of -calculateLayoutThatFits:.
 *
 * @warning You may not override this method. Override -calculateLayoutThatFits: instead.
 * @warning In almost all cases, prefer the use of A_SCalculateLayout in A_SLayout
 *
 * @param constrainedSize Specifies a minimum and maximum size. The receiver must choose a size that is in this range.
 * @param parentSize The parent node's size. If the parent component does not have a final size in a given dimension,
 *                  then it should be passed as A_SLayoutElementParentDimensionUndefined (for example, if the parent's width
 *                  depends on the child's size).
 *
 * @discussion Though this method does not set the bounds of the view, it does have side effects--caching both the
 * constraint and the result.
 *
 * @return An A_SLayout instance defining the layout of the receiver (and its children, if the box layout model is used).
 */
- (A_SLayout *)layoutThatFits:(A_SSizeRange)constrainedSize parentSize:(CGSize)parentSize;

/**
 * Override this method to compute your layoutElement's layout.
 *
 * @discussion Why do you need to override -calculateLayoutThatFits: instead of -layoutThatFits:parentSize:?
 * The base implementation of -layoutThatFits:parentSize: does the following for you:
 * 1. First, it uses the parentSize parameter to resolve the nodes's size (the one assigned to the size property).
 * 2. Then, it intersects the resolved size with the constrainedSize parameter. If the two don't intersect,
 *    constrainedSize wins. This allows a component to always override its childrens' sizes when computing its layout.
 *    (The analogy for UIView: you might return a certain size from -sizeThatFits:, but a parent view can always override
 *    that size and set your frame to any size.)
 * 3. It caches it result for reuse
 *
 * @param constrainedSize A min and max size. This is computed as described in the description. The A_SLayout you
 *                        return MUST have a size between these two sizes.
 */
- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize;

/**
 * In certain advanced cases, you may want to override this method. Overriding this method allows you to receive the
 * layoutElement's size, parentSize, and constrained size. With these values you could calculate the final constrained size
 * and call -calculateLayoutThatFits: with the result.
 *
 * @warning Overriding this method should be done VERY rarely.
 */
- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
                     restrictedToSize:(A_SLayoutElementSize)size
                 relativeToParentSize:(CGSize)parentSize;

- (BOOL)implementsLayoutMethod;

@end

#pragma mark - A_SLayoutElementStyle

extern NSString * const A_SLayoutElementStyleWidthProperty;
extern NSString * const A_SLayoutElementStyleMinWidthProperty;
extern NSString * const A_SLayoutElementStyleMaxWidthProperty;

extern NSString * const A_SLayoutElementStyleHeightProperty;
extern NSString * const A_SLayoutElementStyleMinHeightProperty;
extern NSString * const A_SLayoutElementStyleMaxHeightProperty;

extern NSString * const A_SLayoutElementStyleSpacingBeforeProperty;
extern NSString * const A_SLayoutElementStyleSpacingAfterProperty;
extern NSString * const A_SLayoutElementStyleFlexGrowProperty;
extern NSString * const A_SLayoutElementStyleFlexShrinkProperty;
extern NSString * const A_SLayoutElementStyleFlexBasisProperty;
extern NSString * const A_SLayoutElementStyleAlignSelfProperty;
extern NSString * const A_SLayoutElementStyleAscenderProperty;
extern NSString * const A_SLayoutElementStyleDescenderProperty;

extern NSString * const A_SLayoutElementStyleLayoutPositionProperty;

@protocol A_SLayoutElementStyleDelegate <NSObject>
- (void)style:(__kindof A_SLayoutElementStyle *)style propertyDidChange:(NSString *)propertyName;
@end

@interface A_SLayoutElementStyle : NSObject <A_SStackLayoutElement, A_SAbsoluteLayoutElement, A_SLayoutElementExtensibility>

/**
 * @abstract Initializes the layoutElement style with a specified delegate
 */
- (instancetype)initWithDelegate:(id<A_SLayoutElementStyleDelegate>)delegate;

/**
 * @abstract The object that acts as the delegate of the style.
 *
 * @discussion The delegate must adopt the A_SLayoutElementStyleDelegate protocol. The delegate is not retained.
 */
@property (nullable, nonatomic, weak, readonly) id<A_SLayoutElementStyleDelegate> delegate;


#pragma mark - Sizing

/**
 * @abstract The width property specifies the height of the content area of an A_SLayoutElement.
 * The minWidth and maxWidth properties override width.
 * Defaults to A_SDimensionAuto
 */
@property (nonatomic, assign, readwrite) A_SDimension width;

/**
 * @abstract The height property specifies the height of the content area of an A_SLayoutElement
 * The minHeight and maxHeight properties override height.
 * Defaults to A_SDimensionAuto
 */
@property (nonatomic, assign, readwrite) A_SDimension height;

/**
 * @abstract The minHeight property is used to set the minimum height of a given element. It prevents the used value
 * of the height property from becoming smaller than the value specified for minHeight.
 * The value of minHeight overrides both maxHeight and height.
 * Defaults to A_SDimensionAuto
 */
@property (nonatomic, assign, readwrite) A_SDimension minHeight;

/**
 * @abstract The maxHeight property is used to set the maximum height of an element. It prevents the used value of the
 * height property from becoming larger than the value specified for maxHeight.
 * The value of maxHeight overrides height, but minHeight overrides maxHeight.
 * Defaults to A_SDimensionAuto
 */
@property (nonatomic, assign, readwrite) A_SDimension maxHeight;

/**
 * @abstract The minWidth property is used to set the minimum width of a given element. It prevents the used value of
 * the width property from becoming smaller than the value specified for minWidth.
 * The value of minWidth overrides both maxWidth and width.
 * Defaults to A_SDimensionAuto
 */
@property (nonatomic, assign, readwrite) A_SDimension minWidth;

/**
 * @abstract The maxWidth property is used to set the maximum width of a given element. It prevents the used value of
 * the width property from becoming larger than the value specified for maxWidth.
 * The value of maxWidth overrides width, but minWidth overrides maxWidth.
 * Defaults to A_SDimensionAuto
 */
@property (nonatomic, assign, readwrite) A_SDimension maxWidth;

#pragma mark - A_SLayoutElementStyleSizeHelpers

/**
 * @abstract Provides a suggested size for a layout element. If the optional minSize or maxSize are provided, 
 * and the preferredSize exceeds these, the minSize or maxSize will be enforced. If this optional value is not 
 * provided, the layout element’s size will default to it’s intrinsic content size provided calculateSizeThatFits:
 * 
 * @discussion This method is optional, but one of either preferredSize or preferredLayoutSize is required
 * for nodes that either have no intrinsic content size or 
 * should be laid out at a different size than its intrinsic content size. For example, this property could be 
 * set on an A_SImageNode to display at a size different from the underlying image size.
 *
 * @warning Calling the getter when the size's width or height are relative will cause an assert.
 */
@property (nonatomic, assign) CGSize preferredSize;

 /**
 * @abstract An optional property that provides a minimum size bound for a layout element. If provided, this restriction will 
 * always be enforced. If a parent layout element’s minimum size is smaller than its child’s minimum size, the child’s  
 * minimum size will be enforced and its size will extend out of the layout spec’s.  
 * 
 * @discussion For example, if you set a preferred relative width of 50% and a minimum width of 200 points on an
 * element in a full screen container, this would result in a width of 160 points on an iPhone screen. However, 
 * since 160 pts is lower than the minimum width of 200 pts, the minimum width would be used.
 */
@property (nonatomic, assign) CGSize minSize;
- (CGSize)minSize UNAVAILABLE_ATTRIBUTE;

/**
 * @abstract An optional property that provides a maximum size bound for a layout element. If provided, this restriction will 
 * always be enforced.  If a child layout element’s maximum size is smaller than its parent, the child’s maximum size will 
 * be enforced and its size will extend out of the layout spec’s.  
 * 
 * @discussion For example, if you set a preferred relative width of 50% and a maximum width of 120 points on an
 * element in a full screen container, this would result in a width of 160 points on an iPhone screen. However, 
 * since 160 pts is higher than the maximum width of 120 pts, the maximum width would be used.
 */
@property (nonatomic, assign) CGSize maxSize;
- (CGSize)maxSize UNAVAILABLE_ATTRIBUTE;

/**
 * @abstract Provides a suggested RELATIVE size for a layout element. An A_SLayoutSize uses percentages rather
 * than points to specify layout. E.g. width should be 50% of the parent’s width. If the optional minLayoutSize or
 * maxLayoutSize are provided, and the preferredLayoutSize exceeds these, the minLayoutSize or maxLayoutSize 
 * will be enforced. If this optional value is not provided, the layout element’s size will default to its intrinsic content size 
 * provided calculateSizeThatFits:
 */
@property (nonatomic, assign, readwrite) A_SLayoutSize preferredLayoutSize;

/**
 * @abstract An optional property that provides a minimum RELATIVE size bound for a layout element. If provided, this
 * restriction will always be enforced. If a parent layout element’s minimum relative size is smaller than its child’s minimum
 * relative size, the child’s minimum relative size will be enforced and its size will extend out of the layout spec’s.
 */
@property (nonatomic, assign, readwrite) A_SLayoutSize minLayoutSize;

/**
 * @abstract An optional property that provides a maximum RELATIVE size bound for a layout element. If provided, this
 * restriction will always be enforced. If a parent layout element’s maximum relative size is smaller than its child’s maximum
 * relative size, the child’s maximum relative size will be enforced and its size will extend out of the layout spec’s.
 */
@property (nonatomic, assign, readwrite) A_SLayoutSize maxLayoutSize;

@end

#pragma mark - A_SLayoutElementStylability

@protocol A_SLayoutElementStylability

- (instancetype)styledWithBlock:(A_S_NOESCAPE void (^)(__kindof A_SLayoutElementStyle *style))styleBlock;

@end

NS_ASSUME_NONNULL_END
