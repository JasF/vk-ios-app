//
//  _A_SCollectionGalleryLayoutInfo.m
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/_A_SCollectionGalleryLayoutInfo.h>
#import <Async_DisplayKit/A_SHashing.h>

@implementation _A_SCollectionGalleryLayoutInfo

- (instancetype)initWithItemSize:(CGSize)itemSize
              minimumLineSpacing:(CGFloat)minimumLineSpacing
         minimumInteritemSpacing:(CGFloat)minimumInteritemSpacing
                    sectionInset:(UIEdgeInsets)sectionInset
{
  self = [super init];
  if (self) {
    _itemSize = itemSize;
    _minimumLineSpacing = minimumLineSpacing;
    _minimumInteritemSpacing = minimumInteritemSpacing;
    _sectionInset = sectionInset;
  }
  return self;
}

- (BOOL)isEqualToInfo:(_A_SCollectionGalleryLayoutInfo *)info
{
  if (info == nil) {
    return NO;
  }

  return CGSizeEqualToSize(_itemSize, info.itemSize)
  && _minimumLineSpacing == info.minimumLineSpacing
  && _minimumInteritemSpacing == info.minimumInteritemSpacing
  && UIEdgeInsetsEqualToEdgeInsets(_sectionInset, info.sectionInset);
}

- (BOOL)isEqual:(id)other
{
  if (self == other) {
    return YES;
  }
  if (! [other isKindOfClass:[_A_SCollectionGalleryLayoutInfo class]]) {
    return NO;
  }
  return [self isEqualToInfo:other];
}

- (NSUInteger)hash
{
  struct {
    CGSize itemSize;
    CGFloat minimumLineSpacing;
    CGFloat minimumInteritemSpacing;
    UIEdgeInsets sectionInset;
  } data = {
    _itemSize,
    _minimumLineSpacing,
    _minimumInteritemSpacing,
    _sectionInset,
  };
  return A_SHashBytes(&data, sizeof(data));
}

@end
