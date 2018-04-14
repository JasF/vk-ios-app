//
//  A_SAsciiArtBoxCreator.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol A_SLayoutElementAsciiArtProtocol <NSObject>
/**
 *  Returns an ascii-art representation of this object and its children.
 *  For example, an A_SInsetSpec may return something like this:
 *
 *   --A_SInsetLayoutSpec--
 *   |     A_STextNode    |
 *   ---------------------
 */
- (NSString *)asciiArtString;

/**
 *  returns the name of this object that will display in the ascii art. Usually this can
 *  simply be NSStringFromClass([self class]).
 */
- (NSString *)asciiArtName;

@end

/**
 *  A that takes a parent and its children and renders as ascii art box.
 */
@interface A_SAsciiArtBoxCreator : NSObject

/**
 *  Renders an ascii art box with the children aligned horizontally
 *  Example:
 *  ------------A_SStackLayoutSpec-----------
 *  |  A_STextNode  A_STextNode  A_STextNode  |
 *  ----------------------------------------
 */
+ (NSString *)horizontalBoxStringForChildren:(NSArray<NSString *> *)children parent:(NSString *)parent;

/**
 *  Renders an ascii art box with the children aligned vertically.
 *  Example:
 *   --A_SStackLayoutSpec--
 *   |     A_STextNode    |
 *   |     A_STextNode    |
 *   |     A_STextNode    |
 *   ---------------------
 */
+ (NSString *)verticalBoxStringForChildren:(NSArray<NSString *> *)children parent:(NSString *)parent;

@end

NS_ASSUME_NONNULL_END
