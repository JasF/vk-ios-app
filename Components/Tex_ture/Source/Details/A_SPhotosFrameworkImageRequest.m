//
//  A_SPhotosFrameworkImageRequest.m
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

#import <Async_DisplayKit/A_SPhotosFrameworkImageRequest.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

NSString *const A_SPhotosURLScheme = @"ph";

static NSString *const _A_SPhotosURLQueryKeyWidth = @"width";
static NSString *const _A_SPhotosURLQueryKeyHeight = @"height";

// value is PHImageContentMode value
static NSString *const _A_SPhotosURLQueryKeyContentMode = @"contentmode";

// value is PHImageRequestOptionsResizeMode value
static NSString *const _A_SPhotosURLQueryKeyResizeMode = @"resizemode";

// value is PHImageRequestOptionsDeliveryMode value
static NSString *const _A_SPhotosURLQueryKeyDeliveryMode = @"deliverymode";

// value is PHImageRequestOptionsVersion value
static NSString *const _A_SPhotosURLQueryKeyVersion = @"version";

// value is 0 or 1
static NSString *const _A_SPhotosURLQueryKeyAllowNetworkAccess = @"network";

static NSString *const _A_SPhotosURLQueryKeyCropOriginX = @"crop_x";
static NSString *const _A_SPhotosURLQueryKeyCropOriginY = @"crop_y";
static NSString *const _A_SPhotosURLQueryKeyCropWidth = @"crop_w";
static NSString *const _A_SPhotosURLQueryKeyCropHeight = @"crop_h";

@implementation A_SPhotosFrameworkImageRequest

- (instancetype)init
{
  A_SDISPLAYNODE_NOT_DESIGNATED_INITIALIZER();
  self = [self initWithAssetIdentifier:@""];
  return nil;
}

- (instancetype)initWithAssetIdentifier:(NSString *)assetIdentifier
{
  self = [super init];
  if (self) {
    _assetIdentifier = assetIdentifier;
    _options = [PHImageRequestOptions new];
    _contentMode = PHImageContentModeDefault;
    _targetSize = PHImageManagerMaximumSize;
  }
  return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  A_SPhotosFrameworkImageRequest *copy = [[A_SPhotosFrameworkImageRequest alloc] initWithAssetIdentifier:self.assetIdentifier];
  copy.options = [self.options copy];
  copy.targetSize = self.targetSize;
  copy.contentMode = self.contentMode;
  return copy;
}

#pragma mark Converting to URL

- (NSURL *)url
{
  NSURLComponents *comp = [NSURLComponents new];
  comp.scheme = A_SPhotosURLScheme;
  comp.host = _assetIdentifier;
  NSMutableArray *queryItems = [NSMutableArray arrayWithObjects:
    [NSURLQueryItem queryItemWithName:_A_SPhotosURLQueryKeyWidth value:@(_targetSize.width).stringValue],
    [NSURLQueryItem queryItemWithName:_A_SPhotosURLQueryKeyHeight value:@(_targetSize.height).stringValue],
    [NSURLQueryItem queryItemWithName:_A_SPhotosURLQueryKeyVersion value:@(_options.version).stringValue],
    [NSURLQueryItem queryItemWithName:_A_SPhotosURLQueryKeyContentMode value:@(_contentMode).stringValue],
    [NSURLQueryItem queryItemWithName:_A_SPhotosURLQueryKeyAllowNetworkAccess value:@(_options.networkAccessAllowed).stringValue],
    [NSURLQueryItem queryItemWithName:_A_SPhotosURLQueryKeyResizeMode value:@(_options.resizeMode).stringValue],
    [NSURLQueryItem queryItemWithName:_A_SPhotosURLQueryKeyDeliveryMode value:@(_options.deliveryMode).stringValue]
  , nil];
  
  CGRect cropRect = _options.normalizedCropRect;
  if (!CGRectIsEmpty(cropRect)) {
    [queryItems addObjectsFromArray:@[
      [NSURLQueryItem queryItemWithName:_A_SPhotosURLQueryKeyCropOriginX value:@(cropRect.origin.x).stringValue],
      [NSURLQueryItem queryItemWithName:_A_SPhotosURLQueryKeyCropOriginY value:@(cropRect.origin.y).stringValue],
      [NSURLQueryItem queryItemWithName:_A_SPhotosURLQueryKeyCropWidth value:@(cropRect.size.width).stringValue],
      [NSURLQueryItem queryItemWithName:_A_SPhotosURLQueryKeyCropHeight value:@(cropRect.size.height).stringValue]
    ]];
  }
  comp.queryItems = queryItems;
  return comp.URL;
}

#pragma mark Converting from URL

+ (A_SPhotosFrameworkImageRequest *)requestWithURL:(NSURL *)url
{
  // not a photos URL
  if (![url.scheme isEqualToString:A_SPhotosURLScheme]) {
    return nil;
  }
  
  NSURLComponents *comp = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
  
  A_SPhotosFrameworkImageRequest *request = [[A_SPhotosFrameworkImageRequest alloc] initWithAssetIdentifier:url.host];
  
  CGRect cropRect = CGRectZero;
  CGSize targetSize = PHImageManagerMaximumSize;
  for (NSURLQueryItem *item in comp.queryItems) {
    if ([_A_SPhotosURLQueryKeyAllowNetworkAccess isEqualToString:item.name]) {
      request.options.networkAccessAllowed = item.value.boolValue;
    } else if ([_A_SPhotosURLQueryKeyWidth isEqualToString:item.name]) {
      targetSize.width = item.value.doubleValue;
    } else if ([_A_SPhotosURLQueryKeyHeight isEqualToString:item.name]) {
      targetSize.height = item.value.doubleValue;
    } else if ([_A_SPhotosURLQueryKeyContentMode isEqualToString:item.name]) {
      request.contentMode = (PHImageContentMode)item.value.integerValue;
    } else if ([_A_SPhotosURLQueryKeyVersion isEqualToString:item.name]) {
      request.options.version = (PHImageRequestOptionsVersion)item.value.integerValue;
    } else if ([_A_SPhotosURLQueryKeyCropOriginX isEqualToString:item.name]) {
      cropRect.origin.x = item.value.doubleValue;
    } else if ([_A_SPhotosURLQueryKeyCropOriginY isEqualToString:item.name]) {
      cropRect.origin.y = item.value.doubleValue;
    } else if ([_A_SPhotosURLQueryKeyCropWidth isEqualToString:item.name]) {
      cropRect.size.width = item.value.doubleValue;
    } else if ([_A_SPhotosURLQueryKeyCropHeight isEqualToString:item.name]) {
      cropRect.size.height = item.value.doubleValue;
    } else if ([_A_SPhotosURLQueryKeyResizeMode isEqualToString:item.name]) {
      request.options.resizeMode = (PHImageRequestOptionsResizeMode)item.value.integerValue;
    } else if ([_A_SPhotosURLQueryKeyDeliveryMode isEqualToString:item.name]) {
      request.options.deliveryMode = (PHImageRequestOptionsDeliveryMode)item.value.integerValue;
    }
  }
  request.targetSize = targetSize;
  request.options.normalizedCropRect = cropRect;
  return request;
}

#pragma mark NSObject

- (BOOL)isEqual:(id)object
{
  if (![object isKindOfClass:A_SPhotosFrameworkImageRequest.class]) {
    return NO;
  }
  A_SPhotosFrameworkImageRequest *other = object;
  return [other.assetIdentifier isEqualToString:self.assetIdentifier] &&
    other.contentMode == self.contentMode &&
    CGSizeEqualToSize(other.targetSize, self.targetSize) &&
    CGRectEqualToRect(other.options.normalizedCropRect, self.options.normalizedCropRect) &&
    other.options.resizeMode == self.options.resizeMode &&
    other.options.version == self.options.version;
}

@end
