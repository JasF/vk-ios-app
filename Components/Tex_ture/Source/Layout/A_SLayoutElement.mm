//
//  A_SLayoutElement.mm
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

#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SAvailability.h>
#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SLayoutElement.h>
#import <Async_DisplayKit/A_SThread.h>
#import <Async_DisplayKit/A_SObjectDescriptionHelpers.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>

#import <atomic>

#if YOGA
  #import YOGA_HEADER_PATH
  #import <Async_DisplayKit/A_SYogaUtilities.h>
#endif

#pragma mark - A_SLayoutElementContext

@implementation A_SLayoutElementContext

- (instancetype)init
{
  if (self = [super init]) {
    _transitionID = A_SLayoutElementContextDefaultTransitionID;
  }
  return self;
}

@end

CGFloat const A_SLayoutElementParentDimensionUndefined = NAN;
CGSize const A_SLayoutElementParentSizeUndefined = {A_SLayoutElementParentDimensionUndefined, A_SLayoutElementParentDimensionUndefined};

int32_t const A_SLayoutElementContextInvalidTransitionID = 0;
int32_t const A_SLayoutElementContextDefaultTransitionID = A_SLayoutElementContextInvalidTransitionID + 1;

static void A_SLayoutElementDestructor(void *p) {
  if (p != NULL) {
    A_SDisplayNodeCFailAssert(@"Thread exited without clearing layout element context!");
    CFBridgingRelease(p);
  }
};

pthread_key_t A_SLayoutElementContextKey()
{
  return A_SPthreadStaticKey(A_SLayoutElementDestructor);
}

void A_SLayoutElementPushContext(A_SLayoutElementContext *context)
{
  // NOTE: It would be easy to support nested contexts – just use an NSMutableArray here.
  A_SDisplayNodeCAssertNil(A_SLayoutElementGetCurrentContext(), @"Nested A_SLayoutElementContexts aren't supported.");
  pthread_setspecific(A_SLayoutElementContextKey(), CFBridgingRetain(context));
}

A_SLayoutElementContext *A_SLayoutElementGetCurrentContext()
{
  // Don't retain here. Caller will retain if it wants to!
  return (__bridge __unsafe_unretained A_SLayoutElementContext *)pthread_getspecific(A_SLayoutElementContextKey());
}

void A_SLayoutElementPopContext()
{
  A_SLayoutElementContextKey();
  A_SDisplayNodeCAssertNotNil(A_SLayoutElementGetCurrentContext(), @"Attempt to pop context when there wasn't a context!");
  auto key = A_SLayoutElementContextKey();
  CFBridgingRelease(pthread_getspecific(key));
  pthread_setspecific(key, NULL);
}

#pragma mark - A_SLayoutElementStyle

NSString * const A_SLayoutElementStyleWidthProperty = @"A_SLayoutElementStyleWidthProperty";
NSString * const A_SLayoutElementStyleMinWidthProperty = @"A_SLayoutElementStyleMinWidthProperty";
NSString * const A_SLayoutElementStyleMaxWidthProperty = @"A_SLayoutElementStyleMaxWidthProperty";

NSString * const A_SLayoutElementStyleHeightProperty = @"A_SLayoutElementStyleHeightProperty";
NSString * const A_SLayoutElementStyleMinHeightProperty = @"A_SLayoutElementStyleMinHeightProperty";
NSString * const A_SLayoutElementStyleMaxHeightProperty = @"A_SLayoutElementStyleMaxHeightProperty";

NSString * const A_SLayoutElementStyleSpacingBeforeProperty = @"A_SLayoutElementStyleSpacingBeforeProperty";
NSString * const A_SLayoutElementStyleSpacingAfterProperty = @"A_SLayoutElementStyleSpacingAfterProperty";
NSString * const A_SLayoutElementStyleFlexGrowProperty = @"A_SLayoutElementStyleFlexGrowProperty";
NSString * const A_SLayoutElementStyleFlexShrinkProperty = @"A_SLayoutElementStyleFlexShrinkProperty";
NSString * const A_SLayoutElementStyleFlexBasisProperty = @"A_SLayoutElementStyleFlexBasisProperty";
NSString * const A_SLayoutElementStyleAlignSelfProperty = @"A_SLayoutElementStyleAlignSelfProperty";
NSString * const A_SLayoutElementStyleAscenderProperty = @"A_SLayoutElementStyleAscenderProperty";
NSString * const A_SLayoutElementStyleDescenderProperty = @"A_SLayoutElementStyleDescenderProperty";

NSString * const A_SLayoutElementStyleLayoutPositionProperty = @"A_SLayoutElementStyleLayoutPositionProperty";

#if YOGA
NSString * const A_SYogaFlexWrapProperty = @"A_SLayoutElementStyleLayoutFlexWrapProperty";
NSString * const A_SYogaFlexDirectionProperty = @"A_SYogaFlexDirectionProperty";
NSString * const A_SYogaDirectionProperty = @"A_SYogaDirectionProperty";
NSString * const A_SYogaSpacingProperty = @"A_SYogaSpacingProperty";
NSString * const A_SYogaJustifyContentProperty = @"A_SYogaJustifyContentProperty";
NSString * const A_SYogaAlignItemsProperty = @"A_SYogaAlignItemsProperty";
NSString * const A_SYogaPositionTypeProperty = @"A_SYogaPositionTypeProperty";
NSString * const A_SYogaPositionProperty = @"A_SYogaPositionProperty";
NSString * const A_SYogaMarginProperty = @"A_SYogaMarginProperty";
NSString * const A_SYogaPaddingProperty = @"A_SYogaPaddingProperty";
NSString * const A_SYogaBorderProperty = @"A_SYogaBorderProperty";
NSString * const A_SYogaAspectRatioProperty = @"A_SYogaAspectRatioProperty";
#endif

#define A_SLayoutElementStyleSetSizeWithScope(x) \
  __instanceLock__.lock(); \
  A_SLayoutElementSize newSize = _size.load(); \
  { x } \
  _size.store(newSize); \
  __instanceLock__.unlock();

#define A_SLayoutElementStyleCallDelegate(propertyName)\
do {\
  [self propertyDidChange:propertyName];\
  [_delegate style:self propertyDidChange:propertyName];\
} while(0)

@implementation A_SLayoutElementStyle {
  A_SDN::RecursiveMutex __instanceLock__;
  A_SLayoutElementStyleExtensions _extensions;
  
  std::atomic<A_SLayoutElementSize> _size;
  std::atomic<CGFloat> _spacingBefore;
  std::atomic<CGFloat> _spacingAfter;
  std::atomic<CGFloat> _flexGrow;
  std::atomic<CGFloat> _flexShrink;
  std::atomic<A_SDimension> _flexBasis;
  std::atomic<A_SStackLayoutAlignSelf> _alignSelf;
  std::atomic<CGFloat> _ascender;
  std::atomic<CGFloat> _descender;
  std::atomic<CGPoint> _layoutPosition;

#if YOGA
  YGNodeRef _yogaNode;
  std::atomic<YGWrap> _flexWrap;
  std::atomic<A_SStackLayoutDirection> _flexDirection;
  std::atomic<YGDirection> _direction;
  std::atomic<A_SStackLayoutJustifyContent> _justifyContent;
  std::atomic<A_SStackLayoutAlignItems> _alignItems;
  std::atomic<YGPositionType> _positionType;
  std::atomic<A_SEdgeInsets> _position;
  std::atomic<A_SEdgeInsets> _margin;
  std::atomic<A_SEdgeInsets> _padding;
  std::atomic<A_SEdgeInsets> _border;
  std::atomic<CGFloat> _aspectRatio;
#endif
}

@dynamic width, height, minWidth, maxWidth, minHeight, maxHeight;
@dynamic preferredSize, minSize, maxSize, preferredLayoutSize, minLayoutSize, maxLayoutSize;

#pragma mark - Lifecycle

- (instancetype)initWithDelegate:(id<A_SLayoutElementStyleDelegate>)delegate
{
  self = [self init];
  if (self) {
    _delegate = delegate;
  }
  return self;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _size = A_SLayoutElementSizeMake();
  }
  return self;
}

#pragma mark - A_SLayoutElementStyleSize

- (A_SLayoutElementSize)size
{
  return _size.load();
}

- (void)setSize:(A_SLayoutElementSize)size
{
  A_SLayoutElementStyleSetSizeWithScope({
    newSize = size;
  });
  // No CallDelegate method as A_SLayoutElementSize is currently internal.
}

#pragma mark - A_SLayoutElementStyleSizeForwarding

- (A_SDimension)width
{
  return _size.load().width;
}

- (void)setWidth:(A_SDimension)width
{
  A_SLayoutElementStyleSetSizeWithScope({
    newSize.width = width;
  });
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleWidthProperty);
}

- (A_SDimension)height
{
  return _size.load().height;
}

- (void)setHeight:(A_SDimension)height
{
  A_SLayoutElementStyleSetSizeWithScope({
    newSize.height = height;
  });
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleHeightProperty);
}

- (A_SDimension)minWidth
{
  return _size.load().minWidth;
}

- (void)setMinWidth:(A_SDimension)minWidth
{
  A_SLayoutElementStyleSetSizeWithScope({
    newSize.minWidth = minWidth;
  });
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleMinWidthProperty);
}

- (A_SDimension)maxWidth
{
  return _size.load().maxWidth;
}

- (void)setMaxWidth:(A_SDimension)maxWidth
{
  A_SLayoutElementStyleSetSizeWithScope({
    newSize.maxWidth = maxWidth;
  });
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleMaxWidthProperty);
}

- (A_SDimension)minHeight
{
  return _size.load().minHeight;
}

- (void)setMinHeight:(A_SDimension)minHeight
{
  A_SLayoutElementStyleSetSizeWithScope({
    newSize.minHeight = minHeight;
  });
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleMinHeightProperty);
}

- (A_SDimension)maxHeight
{
  return _size.load().maxHeight;
}

- (void)setMaxHeight:(A_SDimension)maxHeight
{
  A_SLayoutElementStyleSetSizeWithScope({
    newSize.maxHeight = maxHeight;
  });
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleMaxHeightProperty);
}


#pragma mark - A_SLayoutElementStyleSizeHelpers

- (void)setPreferredSize:(CGSize)preferredSize
{
  A_SLayoutElementStyleSetSizeWithScope({
    newSize.width = A_SDimensionMakeWithPoints(preferredSize.width);
    newSize.height = A_SDimensionMakeWithPoints(preferredSize.height);
  });
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleWidthProperty);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleHeightProperty);
}

- (CGSize)preferredSize
{
  A_SLayoutElementSize size = _size.load();
  if (size.width.unit == A_SDimensionUnitFraction) {
    NSCAssert(NO, @"Cannot get preferredSize of element with fractional width. Width: %@.", NSStringFromA_SDimension(size.width));
    return CGSizeZero;
  }
  
  if (size.height.unit == A_SDimensionUnitFraction) {
    NSCAssert(NO, @"Cannot get preferredSize of element with fractional height. Height: %@.", NSStringFromA_SDimension(size.height));
    return CGSizeZero;
  }
  
  return CGSizeMake(size.width.value, size.height.value);
}

- (void)setMinSize:(CGSize)minSize
{
  A_SLayoutElementStyleSetSizeWithScope({
    newSize.minWidth = A_SDimensionMakeWithPoints(minSize.width);
    newSize.minHeight = A_SDimensionMakeWithPoints(minSize.height);
  });
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleMinWidthProperty);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleMinHeightProperty);
}

- (void)setMaxSize:(CGSize)maxSize
{
  A_SLayoutElementStyleSetSizeWithScope({
    newSize.maxWidth = A_SDimensionMakeWithPoints(maxSize.width);
    newSize.maxHeight = A_SDimensionMakeWithPoints(maxSize.height);
  });
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleMaxWidthProperty);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleMaxHeightProperty);
}

- (A_SLayoutSize)preferredLayoutSize
{
  A_SLayoutElementSize size = _size.load();
  return A_SLayoutSizeMake(size.width, size.height);
}

- (void)setPreferredLayoutSize:(A_SLayoutSize)preferredLayoutSize
{
  A_SLayoutElementStyleSetSizeWithScope({
    newSize.width = preferredLayoutSize.width;
    newSize.height = preferredLayoutSize.height;
  });
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleWidthProperty);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleHeightProperty);
}

- (A_SLayoutSize)minLayoutSize
{
  A_SLayoutElementSize size = _size.load();
  return A_SLayoutSizeMake(size.minWidth, size.minHeight);
}

- (void)setMinLayoutSize:(A_SLayoutSize)minLayoutSize
{
  A_SLayoutElementStyleSetSizeWithScope({
    newSize.minWidth = minLayoutSize.width;
    newSize.minHeight = minLayoutSize.height;
  });
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleMinWidthProperty);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleMinHeightProperty);
}

- (A_SLayoutSize)maxLayoutSize
{
  A_SLayoutElementSize size = _size.load();
  return A_SLayoutSizeMake(size.maxWidth, size.maxHeight);
}

- (void)setMaxLayoutSize:(A_SLayoutSize)maxLayoutSize
{
  A_SLayoutElementStyleSetSizeWithScope({
    newSize.maxWidth = maxLayoutSize.width;
    newSize.maxHeight = maxLayoutSize.height;
  });
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleMaxWidthProperty);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleMaxHeightProperty);
}

#pragma mark - A_SStackLayoutElement

- (void)setSpacingBefore:(CGFloat)spacingBefore
{
  _spacingBefore.store(spacingBefore);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleSpacingBeforeProperty);
}

- (CGFloat)spacingBefore
{
  return _spacingBefore.load();
}

- (void)setSpacingAfter:(CGFloat)spacingAfter
{
  _spacingAfter.store(spacingAfter);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleSpacingAfterProperty);
}

- (CGFloat)spacingAfter
{
  return _spacingAfter.load();
}

- (void)setFlexGrow:(CGFloat)flexGrow
{
  _flexGrow.store(flexGrow);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleFlexGrowProperty);
}

- (CGFloat)flexGrow
{
  return _flexGrow.load();
}

- (void)setFlexShrink:(CGFloat)flexShrink
{
  _flexShrink.store(flexShrink);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleFlexShrinkProperty);
}

- (CGFloat)flexShrink
{
  return _flexShrink.load();
}

- (void)setFlexBasis:(A_SDimension)flexBasis
{
  _flexBasis.store(flexBasis);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleFlexBasisProperty);
}

- (A_SDimension)flexBasis
{
  return _flexBasis.load();
}

- (void)setAlignSelf:(A_SStackLayoutAlignSelf)alignSelf
{
  _alignSelf.store(alignSelf);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleAlignSelfProperty);
}

- (A_SStackLayoutAlignSelf)alignSelf
{
  return _alignSelf.load();
}

- (void)setAscender:(CGFloat)ascender
{
  _ascender.store(ascender);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleAscenderProperty);
}

- (CGFloat)ascender
{
  return _ascender.load();
}

- (void)setDescender:(CGFloat)descender
{
  _descender.store(descender);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleDescenderProperty);
}

- (CGFloat)descender
{
  return _descender.load();
}

#pragma mark - A_SAbsoluteLayoutElement

- (void)setLayoutPosition:(CGPoint)layoutPosition
{
  _layoutPosition.store(layoutPosition);
  A_SLayoutElementStyleCallDelegate(A_SLayoutElementStyleLayoutPositionProperty);
}

- (CGPoint)layoutPosition
{
  return _layoutPosition.load();
}

#pragma mark - Extensions

- (void)setLayoutOptionExtensionBool:(BOOL)value atIndex:(int)idx
{
  NSCAssert(idx < kMaxLayoutElementBoolExtensions, @"Setting index outside of max bool extensions space");
  
  A_SDN::MutexLocker l(__instanceLock__);
  _extensions.boolExtensions[idx] = value;
}

- (BOOL)layoutOptionExtensionBoolAtIndex:(int)idx\
{
  NSCAssert(idx < kMaxLayoutElementBoolExtensions, @"Accessing index outside of max bool extensions space");
  
  A_SDN::MutexLocker l(__instanceLock__);
  return _extensions.boolExtensions[idx];
}

- (void)setLayoutOptionExtensionInteger:(NSInteger)value atIndex:(int)idx
{
  NSCAssert(idx < kMaxLayoutElementStateIntegerExtensions, @"Setting index outside of max integer extensions space");
  
  A_SDN::MutexLocker l(__instanceLock__);
  _extensions.integerExtensions[idx] = value;
}

- (NSInteger)layoutOptionExtensionIntegerAtIndex:(int)idx
{
  NSCAssert(idx < kMaxLayoutElementStateIntegerExtensions, @"Accessing index outside of max integer extensions space");
  
  A_SDN::MutexLocker l(__instanceLock__);
  return _extensions.integerExtensions[idx];
}

- (void)setLayoutOptionExtensionEdgeInsets:(UIEdgeInsets)value atIndex:(int)idx
{
  NSCAssert(idx < kMaxLayoutElementStateEdgeInsetExtensions, @"Setting index outside of max edge insets extensions space");
  
  A_SDN::MutexLocker l(__instanceLock__);
  _extensions.edgeInsetsExtensions[idx] = value;
}

- (UIEdgeInsets)layoutOptionExtensionEdgeInsetsAtIndex:(int)idx
{
  NSCAssert(idx < kMaxLayoutElementStateEdgeInsetExtensions, @"Accessing index outside of max edge insets extensions space");
  
  A_SDN::MutexLocker l(__instanceLock__);
  return _extensions.edgeInsetsExtensions[idx];
}

#pragma mark - Debugging

- (NSString *)description
{
  return A_SObjectDescriptionMake(self, [self propertiesForDescription]);
}

- (NSMutableArray<NSDictionary *> *)propertiesForDescription
{
  NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
  
  if ((self.minLayoutSize.width.unit != A_SDimensionUnitAuto ||
    self.minLayoutSize.height.unit != A_SDimensionUnitAuto)) {
    [result addObject:@{ @"minLayoutSize" : NSStringFromA_SLayoutSize(self.minLayoutSize) }];
  }
  
  if ((self.preferredLayoutSize.width.unit != A_SDimensionUnitAuto ||
    self.preferredLayoutSize.height.unit != A_SDimensionUnitAuto)) {
    [result addObject:@{ @"preferredSize" : NSStringFromA_SLayoutSize(self.preferredLayoutSize) }];
  }
  
  if ((self.maxLayoutSize.width.unit != A_SDimensionUnitAuto ||
    self.maxLayoutSize.height.unit != A_SDimensionUnitAuto)) {
    [result addObject:@{ @"maxLayoutSize" : NSStringFromA_SLayoutSize(self.maxLayoutSize) }];
  }
  
  if (self.alignSelf != A_SStackLayoutAlignSelfAuto) {
    [result addObject:@{ @"alignSelf" : [@[@"A_SStackLayoutAlignSelfAuto",
                                          @"A_SStackLayoutAlignSelfStart",
                                          @"A_SStackLayoutAlignSelfEnd",
                                          @"A_SStackLayoutAlignSelfCenter",
                                          @"A_SStackLayoutAlignSelfStretch"] objectAtIndex:self.alignSelf] }];
  }
  
  if (self.ascender != 0) {
    [result addObject:@{ @"ascender" : @(self.ascender) }];
  }
  
  if (self.descender != 0) {
    [result addObject:@{ @"descender" : @(self.descender) }];
  }
  
  if (A_SDimensionEqualToDimension(self.flexBasis, A_SDimensionAuto) == NO) {
    [result addObject:@{ @"flexBasis" : NSStringFromA_SDimension(self.flexBasis) }];
  }
  
  if (self.flexGrow != 0) {
    [result addObject:@{ @"flexGrow" : @(self.flexGrow) }];
  }
  
  if (self.flexShrink != 0) {
    [result addObject:@{ @"flexShrink" : @(self.flexShrink) }];
  }
  
  if (self.spacingAfter != 0) {
    [result addObject:@{ @"spacingAfter" : @(self.spacingAfter) }];
  }
  
  if (self.spacingBefore != 0) {
    [result addObject:@{ @"spacingBefore" : @(self.spacingBefore) }];
  }
  
  if (CGPointEqualToPoint(self.layoutPosition, CGPointZero) == NO) {
    [result addObject:@{ @"layoutPosition" : [NSValue valueWithCGPoint:self.layoutPosition] }];
  }

  return result;
}

- (void)propertyDidChange:(NSString *)propertyName
{
#if YOGA
  /* TODO(appleguy): STYLE SETTER METHODS LEFT TO IMPLEMENT
   void YGNodeStyleSetOverflow(YGNodeRef node, YGOverflow overflow);
   void YGNodeStyleSetFlex(YGNodeRef node, float flex);
   */

  if (_yogaNode == NULL) {
    return;
  }
  // Because the NSStrings used to identify each property are const, use efficient pointer comparison.
  if (propertyName == A_SLayoutElementStyleWidthProperty) {
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, Width, self.width);
  }
  else if (propertyName == A_SLayoutElementStyleMinWidthProperty) {
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinWidth, self.minWidth);
  }
  else if (propertyName == A_SLayoutElementStyleMaxWidthProperty) {
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxWidth, self.maxWidth);
  }
  else if (propertyName == A_SLayoutElementStyleHeightProperty) {
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, Height, self.height);
  }
  else if (propertyName == A_SLayoutElementStyleMinHeightProperty) {
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinHeight, self.minHeight);
  }
  else if (propertyName == A_SLayoutElementStyleMaxHeightProperty) {
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxHeight, self.maxHeight);
  }
  else if (propertyName == A_SLayoutElementStyleFlexGrowProperty) {
    YGNodeStyleSetFlexGrow(_yogaNode, self.flexGrow);
  }
  else if (propertyName == A_SLayoutElementStyleFlexShrinkProperty) {
    YGNodeStyleSetFlexShrink(_yogaNode, self.flexShrink);
  }
  else if (propertyName == A_SLayoutElementStyleFlexBasisProperty) {
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, FlexBasis, self.flexBasis);
  }
  else if (propertyName == A_SLayoutElementStyleAlignSelfProperty) {
    YGNodeStyleSetAlignSelf(_yogaNode, yogaAlignSelf(self.alignSelf));
  }
  else if (propertyName == A_SYogaFlexWrapProperty) {
    YGNodeStyleSetFlexWrap(_yogaNode, self.flexWrap);
  }
  else if (propertyName == A_SYogaFlexDirectionProperty) {
    YGNodeStyleSetFlexDirection(_yogaNode, yogaFlexDirection(self.flexDirection));
  }
  else if (propertyName == A_SYogaDirectionProperty) {
    YGNodeStyleSetDirection(_yogaNode, self.direction);
  }
  else if (propertyName == A_SYogaJustifyContentProperty) {
    YGNodeStyleSetJustifyContent(_yogaNode, yogaJustifyContent(self.justifyContent));
  }
  else if (propertyName == A_SYogaAlignItemsProperty) {
    A_SStackLayoutAlignItems alignItems = self.alignItems;
    if (alignItems != A_SStackLayoutAlignItemsNotSet) {
      YGNodeStyleSetAlignItems(_yogaNode, yogaAlignItems(alignItems));
    }
  }
  else if (propertyName == A_SYogaPositionTypeProperty) {
    YGNodeStyleSetPositionType(_yogaNode, self.positionType);
  }
  else if (propertyName == A_SYogaPositionProperty) {
    A_SEdgeInsets position = self.position;
    YGEdge edge = YGEdgeLeft;
    for (int i = 0; i < YGEdgeAll + 1; ++i) {
      YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Position, dimensionForEdgeWithEdgeInsets(edge, position), edge);
      edge = (YGEdge)(edge + 1);
    }
  }
  else if (propertyName == A_SYogaMarginProperty) {
    A_SEdgeInsets margin   = self.margin;
    YGEdge edge = YGEdgeLeft;
    for (int i = 0; i < YGEdgeAll + 1; ++i) {
      YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Margin, dimensionForEdgeWithEdgeInsets(edge, margin), edge);
      edge = (YGEdge)(edge + 1);
    }
  }
  else if (propertyName == A_SYogaPaddingProperty) {
    A_SEdgeInsets padding  = self.padding;
    YGEdge edge = YGEdgeLeft;
    for (int i = 0; i < YGEdgeAll + 1; ++i) {
      YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Padding, dimensionForEdgeWithEdgeInsets(edge, padding), edge);
      edge = (YGEdge)(edge + 1);
    }
  }
  else if (propertyName == A_SYogaBorderProperty) {
    A_SEdgeInsets border   = self.border;
    YGEdge edge = YGEdgeLeft;
    for (int i = 0; i < YGEdgeAll + 1; ++i) {
      YGNODE_STYLE_SET_FLOAT_WITH_EDGE(_yogaNode, Border, dimensionForEdgeWithEdgeInsets(edge, border), edge);
      edge = (YGEdge)(edge + 1);
    }
  }
  else if (propertyName == A_SYogaAspectRatioProperty) {
    CGFloat aspectRatio = self.aspectRatio;
    if (aspectRatio > FLT_EPSILON && aspectRatio < CGFLOAT_MAX / 2.0) {
      YGNodeStyleSetAspectRatio(_yogaNode, aspectRatio);
    }
  }
#endif
}

#pragma mark - Yoga Flexbox Properties

#if YOGA

+ (void)initialize
{
  [super initialize];
  YGConfigSetPointScaleFactor(YGConfigGetDefault(), A_SScreenScale());
  // Yoga recommends using Web Defaults for all new projects. This will be enabled for Tex_ture very soon.
  //YGConfigSetUseWebDefaults(YGConfigGetDefault(), true);
}

- (YGNodeRef)yogaNode
{
  return _yogaNode;
}

- (YGNodeRef)yogaNodeCreateIfNeeded
{
  if (_yogaNode == NULL) {
    _yogaNode = YGNodeNew();
  }
  return _yogaNode;
}

- (void)destroyYogaNode
{
  if (_yogaNode != NULL) {
    // Release the __bridge_retained Context object.
    A_SLayoutElementYogaUpdateMeasureFunc(_yogaNode, nil);
    YGNodeFree(_yogaNode);
    _yogaNode = NULL;
  }
}

- (void)dealloc
{
  [self destroyYogaNode];
}

- (YGWrap)flexWrap                            { return _flexWrap.load(); }
- (A_SStackLayoutDirection)flexDirection       { return _flexDirection.load(); }
- (YGDirection)direction                      { return _direction.load(); }
- (A_SStackLayoutJustifyContent)justifyContent { return _justifyContent.load(); }
- (A_SStackLayoutAlignItems)alignItems         { return _alignItems.load(); }
- (YGPositionType)positionType                { return _positionType.load(); }
- (A_SEdgeInsets)position                      { return _position.load(); }
- (A_SEdgeInsets)margin                        { return _margin.load(); }
- (A_SEdgeInsets)padding                       { return _padding.load(); }
- (A_SEdgeInsets)border                        { return _border.load(); }
- (CGFloat)aspectRatio                        { return _aspectRatio.load(); }

- (void)setFlexWrap:(YGWrap)flexWrap {
  _flexWrap.store(flexWrap);
  A_SLayoutElementStyleCallDelegate(A_SYogaFlexWrapProperty);
}
- (void)setFlexDirection:(A_SStackLayoutDirection)flexDirection {
  _flexDirection.store(flexDirection);
  A_SLayoutElementStyleCallDelegate(A_SYogaFlexDirectionProperty);
}
- (void)setDirection:(YGDirection)direction {
  _direction.store(direction);
  A_SLayoutElementStyleCallDelegate(A_SYogaDirectionProperty);
}
- (void)setJustifyContent:(A_SStackLayoutJustifyContent)justify {
  _justifyContent.store(justify);
  A_SLayoutElementStyleCallDelegate(A_SYogaJustifyContentProperty);
}
- (void)setAlignItems:(A_SStackLayoutAlignItems)alignItems {
  _alignItems.store(alignItems);
  A_SLayoutElementStyleCallDelegate(A_SYogaAlignItemsProperty);
}
- (void)setPositionType:(YGPositionType)positionType {
  _positionType.store(positionType);
  A_SLayoutElementStyleCallDelegate(A_SYogaPositionTypeProperty);
}
- (void)setPosition:(A_SEdgeInsets)position {
  _position.store(position);
  A_SLayoutElementStyleCallDelegate(A_SYogaPositionProperty);
}
- (void)setMargin:(A_SEdgeInsets)margin {
  _margin.store(margin);
  A_SLayoutElementStyleCallDelegate(A_SYogaMarginProperty);
}
- (void)setPadding:(A_SEdgeInsets)padding {
  _padding.store(padding);
  A_SLayoutElementStyleCallDelegate(A_SYogaPaddingProperty);
}
- (void)setBorder:(A_SEdgeInsets)border {
  _border.store(border);
  A_SLayoutElementStyleCallDelegate(A_SYogaBorderProperty);
}
- (void)setAspectRatio:(CGFloat)aspectRatio {
  _aspectRatio.store(aspectRatio);
  A_SLayoutElementStyleCallDelegate(A_SYogaAspectRatioProperty);
}

#endif /* YOGA */

@end
