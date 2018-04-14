//
//  _A_SScopeTimer.h
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

#pragma once

/**
 Must compile as c++ for this to work.

 Usage:
 // Can be an ivar or local variable
 NSTimeInterval placeToStoreTiming;

 {
   // some scope
   A_SDisplayNode::ScopeTimer t(placeToStoreTiming);
   DoPotentiallySlowWork();
   MorePotentiallySlowWork();
 }

 */

namespace A_SDN {
  struct ScopeTimer {
    NSTimeInterval begin;
    NSTimeInterval &outT;
    ScopeTimer(NSTimeInterval &outRef) : outT(outRef) {
      begin = CACurrentMediaTime();
    }
    ~ScopeTimer() {
      outT = CACurrentMediaTime() - begin;
    }
  };

  // variant where repeated calls are summed
  struct SumScopeTimer {
    NSTimeInterval begin;
    NSTimeInterval &outT;
    BOOL enable;
    SumScopeTimer(NSTimeInterval &outRef, BOOL enable = YES) : outT(outRef), enable(enable) {
      if (enable) {
        begin = CACurrentMediaTime();
      }
    }
    ~SumScopeTimer() {
      if (enable) {
        outT += CACurrentMediaTime() - begin;
      }
    }
  };
}
