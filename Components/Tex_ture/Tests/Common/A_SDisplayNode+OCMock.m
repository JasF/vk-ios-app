//
//  A_SDisplayNode+OCMock.m
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/Async_DisplayKit.h>

/**
 * For some reason, when creating partial mocks of nodes, OCMock fails to find
 * these class methods that it swizzled!
 */
@implementation A_SDisplayNode (OCMock)

+ (Class)ocmock_replaced_viewClass
{
  return [_A_SDisplayView class];
}

+ (Class)ocmock_replaced_layerClass
{
  return [_A_SDisplayLayer class];
}

@end
