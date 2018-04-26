//
//  LayoutExampleViewController.h
//  Sample
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//

#import <Async_DisplayKit/Async_DisplayKit.h>

@interface LayoutExampleViewController : A_SViewController
- (instancetype)initWithLayoutExampleClass:(Class)layoutExampleClass NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNode:(A_SDisplayNode *)node NS_UNAVAILABLE;
@end
