//
//  A_STextKitRenderer+TextChecking.mm
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

#import <Async_DisplayKit/A_STextKitRenderer+TextChecking.h>

#import <Async_DisplayKit/A_STextKitEntityAttribute.h>
#import <Async_DisplayKit/A_STextKitRenderer+Positioning.h>
#import <Async_DisplayKit/A_STextKitTailTruncater.h>

@implementation A_STextKitTextCheckingResult

{
  // Be explicit about the fact that we are overriding the super class' implementation of -range and -resultType
  // and substituting our own custom values. (We could use @synthesize to make these ivars, but our linter correctly
  // complains; it's weird to use @synthesize for properties that are redeclared on top of an original declaration in
  // the superclass. We only do it here because NSTextCheckingResult doesn't expose an initializer, which is silly.)
  NSRange _rangeOverride;
  NSTextCheckingType _resultTypeOverride;
}

- (instancetype)initWithType:(NSTextCheckingType)type
             entityAttribute:(A_STextKitEntityAttribute *)entityAttribute
                       range:(NSRange)range
{
  if ((self = [super init])) {
    _resultTypeOverride = type;
    _rangeOverride = range;
    _entityAttribute = entityAttribute;
  }
  return self;
}

- (NSTextCheckingType)resultType
{
  return _resultTypeOverride;
}

- (NSRange)range
{
  return _rangeOverride;
}

@end

@implementation A_STextKitRenderer (TextChecking)

- (NSTextCheckingResult *)textCheckingResultAtPoint:(CGPoint)point
{
  __block NSTextCheckingResult *result = nil;
  NSAttributedString *attributedString = self.attributes.attributedString;
  NSAttributedString *truncationAttributedString = self.attributes.truncationAttributedString;

  // get the index of the last character, so we can handle text in the truncation token
  __block NSRange truncationTokenRange = { NSNotFound, 0 };

  [truncationAttributedString enumerateAttribute:A_STextKitTruncationAttributeName inRange:NSMakeRange(0, truncationAttributedString.length)
                                         options:0
                                      usingBlock:^(id value, NSRange range, BOOL *stop) {
    if (value != nil && range.length > 0) {
      truncationTokenRange = range;
    }
  }];

  if (truncationTokenRange.location == NSNotFound) {
    // The truncation string didn't specify a substring which should be highlighted, so we just highlight it all
    truncationTokenRange = { 0, truncationAttributedString.length };
  }

  NSRange visibleRange = self.truncater.firstVisibleRange;
  truncationTokenRange.location += NSMaxRange(visibleRange);
  
  __block CGFloat minDistance = CGFLOAT_MAX;
  [self enumerateTextIndexesAtPosition:point usingBlock:^(NSUInteger index, CGRect glyphBoundingRect, BOOL *stop){
    if (index >= truncationTokenRange.location) {
      result = [[A_STextKitTextCheckingResult alloc] initWithType:A_STextKitTextCheckingTypeTruncation
                                                 entityAttribute:nil
                                                           range:truncationTokenRange];
    } else {
      NSRange range;
      NSDictionary *attributes = [attributedString attributesAtIndex:index effectiveRange:&range];
      A_STextKitEntityAttribute *entityAttribute = attributes[A_STextKitEntityAttributeName];
      CGFloat distance = hypot(CGRectGetMidX(glyphBoundingRect) - point.x, CGRectGetMidY(glyphBoundingRect) - point.y);
      if (entityAttribute && distance < minDistance) {
        result = [[A_STextKitTextCheckingResult alloc] initWithType:A_STextKitTextCheckingTypeEntity
                                                   entityAttribute:entityAttribute
                                                             range:range];
        minDistance = distance;
      }
    }
  }];
  return result;
}

@end
