//
//  LoadingNode.m
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /A_SDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) through the present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "LoadingNode.h"

#import <Async_DisplayKit/A_SCenterLayoutSpec.h>

@implementation LoadingNode {
  A_SDisplayNode *_loadingSpinner;
}

#pragma mark - A_SCellNode

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;
  
  _loadingSpinner = [[A_SDisplayNode alloc] initWithViewBlock:^UIView * _Nonnull{
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner startAnimating];
    return spinner;
  }];
  _loadingSpinner.style.preferredSize = CGSizeMake(50, 50);
    
  // add it as a subnode, and we're done
  [self addSubnode:_loadingSpinner];
  
  return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  A_SCenterLayoutSpec *centerSpec = [[A_SCenterLayoutSpec alloc] init];
  centerSpec.centeringOptions = A_SCenterLayoutSpecCenteringXY;
  centerSpec.sizingOptions = A_SCenterLayoutSpecSizingOptionDefault;
  centerSpec.child = _loadingSpinner;
  return centerSpec;
}

@end
