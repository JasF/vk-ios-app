//
//  A_SCollectionGalleryLayoutDelegate.mm
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SCollectionGalleryLayoutDelegate.h>

#import <Async_DisplayKit/_A_SCollectionGalleryLayoutInfo.h>
#import <Async_DisplayKit/_A_SCollectionGalleryLayoutItem.h>
#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SCellNode.h>
#import <Async_DisplayKit/A_SCollectionElement.h>
#import <Async_DisplayKit/A_SCollectionLayoutContext.h>
#import <Async_DisplayKit/A_SCollectionLayoutDefines.h>
#import <Async_DisplayKit/A_SCollectionLayoutState.h>
#import <Async_DisplayKit/A_SElementMap.h>
#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SLayoutRangeType.h>
#import <Async_DisplayKit/A_SInsetLayoutSpec.h>
#import <Async_DisplayKit/A_SStackLayoutSpec.h>

#pragma mark - A_SCollectionGalleryLayoutDelegate

@implementation A_SCollectionGalleryLayoutDelegate {
  A_SScrollDirection _scrollableDirections;

  struct {
    unsigned int minimumLineSpacingForElements:1;
    unsigned int minimumInteritemSpacingForElements:1;
    unsigned int sectionInsetForElements:1;
  } _propertiesProviderFlags;
}

- (instancetype)initWithScrollableDirections:(A_SScrollDirection)scrollableDirections
{
  self = [super init];
  if (self) {
    // Scrollable directions must be either vertical or horizontal, but not both
    A_SDisplayNodeAssertTrue(A_SScrollDirectionContainsVerticalDirection(scrollableDirections)
                            || A_SScrollDirectionContainsHorizontalDirection(scrollableDirections));
    A_SDisplayNodeAssertFalse(A_SScrollDirectionContainsVerticalDirection(scrollableDirections)
                             && A_SScrollDirectionContainsHorizontalDirection(scrollableDirections));
    _scrollableDirections = scrollableDirections;
  }
  return self;
}

- (A_SScrollDirection)scrollableDirections
{
  A_SDisplayNodeAssertMainThread();
  return _scrollableDirections;
}

- (void)setPropertiesProvider:(id<A_SCollectionGalleryLayoutPropertiesProviding>)propertiesProvider
{
  A_SDisplayNodeAssertMainThread();
  if (propertiesProvider == nil) {
    _propertiesProvider = nil;
    _propertiesProviderFlags = {};
  } else {
    _propertiesProvider = propertiesProvider;
    _propertiesProviderFlags.minimumLineSpacingForElements = [_propertiesProvider respondsToSelector:@selector(galleryLayoutDelegate:minimumLineSpacingForElements:)];
    _propertiesProviderFlags.minimumInteritemSpacingForElements = [_propertiesProvider respondsToSelector:@selector(galleryLayoutDelegate:minimumInteritemSpacingForElements:)];
    _propertiesProviderFlags.sectionInsetForElements = [_propertiesProvider respondsToSelector:@selector(galleryLayoutDelegate:sectionInsetForElements:)];
  }
}

- (id)additionalInfoForLayoutWithElements:(A_SElementMap *)elements
{
  A_SDisplayNodeAssertMainThread();
  id<A_SCollectionGalleryLayoutPropertiesProviding> propertiesProvider = _propertiesProvider;
  if (propertiesProvider == nil) {
    return nil;
  }

  CGSize itemSize = [propertiesProvider galleryLayoutDelegate:self sizeForElements:elements];
  UIEdgeInsets sectionInset = _propertiesProviderFlags.sectionInsetForElements ? [propertiesProvider galleryLayoutDelegate:self sectionInsetForElements:elements] : UIEdgeInsetsZero;
  CGFloat lineSpacing = _propertiesProviderFlags.minimumLineSpacingForElements ? [propertiesProvider galleryLayoutDelegate:self minimumLineSpacingForElements:elements] : 0.0;
  CGFloat interitemSpacing = _propertiesProviderFlags.minimumInteritemSpacingForElements ? [propertiesProvider galleryLayoutDelegate:self minimumInteritemSpacingForElements:elements] : 0.0;
  return [[_A_SCollectionGalleryLayoutInfo alloc] initWithItemSize:itemSize
                                               minimumLineSpacing:lineSpacing
                                          minimumInteritemSpacing:interitemSpacing
                                                     sectionInset:sectionInset];
}

+ (A_SCollectionLayoutState *)calculateLayoutWithContext:(A_SCollectionLayoutContext *)context
{
  A_SElementMap *elements = context.elements;
  CGSize pageSize = context.viewportSize;
  A_SScrollDirection scrollableDirections = context.scrollableDirections;

  _A_SCollectionGalleryLayoutInfo *info = A_SDynamicCast(context.additionalInfo, _A_SCollectionGalleryLayoutInfo);
  CGSize itemSize = info.itemSize;
  if (info == nil || CGSizeEqualToSize(CGSizeZero, itemSize)) {
    return [[A_SCollectionLayoutState alloc] initWithContext:context];
  }

  NSMutableArray<_A_SGalleryLayoutItem *> *children = A_SArrayByFlatMapping(elements.itemElements,
                                                                          A_SCollectionElement *element,
                                                                          [[_A_SGalleryLayoutItem alloc] initWithItemSize:itemSize collectionElement:element]);
  if (children.count == 0) {
    return [[A_SCollectionLayoutState alloc] initWithContext:context];
  }

  // Use a stack spec to calculate layout content size and frames of all elements without actually measuring each element
  A_SStackLayoutDirection stackDirection = A_SScrollDirectionContainsVerticalDirection(scrollableDirections)
                                              ? A_SStackLayoutDirectionHorizontal
                                              : A_SStackLayoutDirectionVertical;
  A_SStackLayoutSpec *stackSpec = [A_SStackLayoutSpec stackLayoutSpecWithDirection:stackDirection
                                                                         spacing:info.minimumInteritemSpacing
                                                                  justifyContent:A_SStackLayoutJustifyContentStart
                                                                      alignItems:A_SStackLayoutAlignItemsStart
                                                                        flexWrap:A_SStackLayoutFlexWrapWrap
                                                                    alignContent:A_SStackLayoutAlignContentStart
                                                                     lineSpacing:info.minimumLineSpacing
                                                                        children:children];
  stackSpec.concurrent = YES;

  A_SLayoutSpec *finalSpec = stackSpec;
  UIEdgeInsets sectionInset = info.sectionInset;
  if (UIEdgeInsetsEqualToEdgeInsets(sectionInset, UIEdgeInsetsZero) == NO) {
    finalSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:sectionInset child:stackSpec];
  }

  A_SLayout *layout = [finalSpec layoutThatFits:A_SSizeRangeForCollectionLayoutThatFitsViewportSize(pageSize, scrollableDirections)];

  return [[A_SCollectionLayoutState alloc] initWithContext:context layout:layout getElementBlock:^A_SCollectionElement * _Nullable(A_SLayout * _Nonnull sublayout) {
    _A_SGalleryLayoutItem *item = A_SDynamicCast(sublayout.layoutElement, _A_SGalleryLayoutItem);
    return item ? item.collectionElement : nil;
  }];
}

@end
