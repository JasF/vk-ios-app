//
//  A_SDelegateProxy.h
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

@class A_SDelegateProxy;
@protocol A_SDelegateProxyInterceptor <NSObject>
@required
// Called if the target object is discovered to be nil if it had been non-nil at init time.
// This happens if the object is deallocated, because the proxy must maintain a weak reference to avoid cycles.
// Though the target object may become nil, the interceptor must not; it is assumed the interceptor owns the proxy.
- (void)proxyTargetHasDeallocated:(A_SDelegateProxy *)proxy;
@end

/**
 * Stand-in for delegates like UITableView or UICollectionView's delegate / dataSource.
 * Any selectors flagged by "interceptsSelector" are routed to the interceptor object and are not delivered to the target.
 * Everything else leaves Async_DisplayKit safely and arrives at the original target object.
 */

@interface A_SDelegateProxy : NSProxy

- (instancetype)initWithTarget:(id <NSObject>)target interceptor:(id <A_SDelegateProxyInterceptor>)interceptor;

// This method must be overridden by a subclass.
- (BOOL)interceptsSelector:(SEL)selector;

@end

/**
 * A_STableView intercepts and/or overrides a few of UITableView's critical data source and delegate methods.
 *
 * Any selector included in this function *MUST* be implemented by A_STableView.
 */

@interface A_STableViewProxy : A_SDelegateProxy
@end

/**
 * A_SCollectionView intercepts and/or overrides a few of UICollectionView's critical data source and delegate methods.
 *
 * Any selector included in this function *MUST* be implemented by A_SCollectionView.
 */

@interface A_SCollectionViewProxy : A_SDelegateProxy
@end

@interface A_SPagerNodeProxy : A_SDelegateProxy
@end

