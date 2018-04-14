//
//  _A_SCollectionGalleryLayoutItem.mm
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/_A_SCollectionGalleryLayoutItem.h>

#import <Async_DisplayKit/A_SCollectionElement.h>
#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SLayoutElementPrivate.h>
#import <Async_DisplayKit/A_SLayoutElementStylePrivate.h>
#import <Async_DisplayKit/A_SLayoutSpec.h>

@implementation _A_SGalleryLayoutItem {
  std::atomic<A_SPrimitiveTraitCollection> _primitiveTraitCollection;
}

@synthesize style;

- (instancetype)initWithItemSize:(CGSize)itemSize collectionElement:(A_SCollectionElement *)collectionElement
{
  self = [super init];
  if (self) {
    A_SDisplayNodeAssert(! CGSizeEqualToSize(CGSizeZero, itemSize), @"Item size should not be zero");
    A_SDisplayNodeAssertNotNil(collectionElement, @"Collection element should not be nil");
    _itemSize = itemSize;
    _collectionElement = collectionElement;
  }
  return self;
}

A_SLayoutElementStyleExtensibilityForwarding
A_SPrimitiveTraitCollectionDefaults

- (A_STraitCollection *)asyncTraitCollection
{
  A_SDisplayNodeAssertNotSupported();
  return nil;
}

- (A_SLayoutElementType)layoutElementType
{
  return A_SLayoutElementTypeLayoutSpec;
}

- (NSArray<id<A_SLayoutElement>> *)sublayoutElements
{
  A_SDisplayNodeAssertNotSupported();
  return nil;
}

- (BOOL)implementsLayoutMethod
{
  return YES;
}

A_SLayoutElementLayoutCalculationDefaults

- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
{
  A_SDisplayNodeAssert(CGSizeEqualToSize(_itemSize, A_SSizeRangeClamp(constrainedSize, _itemSize)),
                      @"Item size %@ can't fit within the bounds of constrained size %@", NSStringFromCGSize(_itemSize), NSStringFromA_SSizeRange(constrainedSize));
  return [A_SLayout layoutWithLayoutElement:self size:_itemSize];
}

#pragma mark - A_SLayoutElementAsciiArtProtocol

- (NSString *)asciiArtString
{
  return [A_SLayoutSpec asciiArtStringForChildren:@[] parentName:[self asciiArtName]];
}

- (NSString *)asciiArtName
{
  return [NSMutableString stringWithCString:object_getClassName(self) encoding:NSASCIIStringEncoding];
}

@end
