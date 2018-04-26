//
//  A_SScrollDirection.m
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

#import <Async_DisplayKit/A_SScrollDirection.h>

const A_SScrollDirection A_SScrollDirectionHorizontalDirections = A_SScrollDirectionLeft | A_SScrollDirectionRight;
const A_SScrollDirection A_SScrollDirectionVerticalDirections = A_SScrollDirectionUp | A_SScrollDirectionDown;

BOOL A_SScrollDirectionContainsVerticalDirection(A_SScrollDirection scrollDirection) {
  return (scrollDirection & A_SScrollDirectionVerticalDirections) != 0;
}

BOOL A_SScrollDirectionContainsHorizontalDirection(A_SScrollDirection scrollDirection) {
  return (scrollDirection & A_SScrollDirectionHorizontalDirections) != 0;
}

BOOL A_SScrollDirectionContainsRight(A_SScrollDirection scrollDirection) {
  return (scrollDirection & A_SScrollDirectionRight) != 0;
}

BOOL A_SScrollDirectionContainsLeft(A_SScrollDirection scrollDirection) {
  return (scrollDirection & A_SScrollDirectionLeft) != 0;
}

BOOL A_SScrollDirectionContainsUp(A_SScrollDirection scrollDirection) {
  return (scrollDirection & A_SScrollDirectionUp) != 0;
}

BOOL A_SScrollDirectionContainsDown(A_SScrollDirection scrollDirection) {
  return (scrollDirection & A_SScrollDirectionDown) != 0;
}

A_SScrollDirection A_SScrollDirectionInvertHorizontally(A_SScrollDirection scrollDirection) {
  if (scrollDirection == A_SScrollDirectionRight) {
    return A_SScrollDirectionLeft;
  } else if (scrollDirection == A_SScrollDirectionLeft) {
    return A_SScrollDirectionRight;
  }
  return scrollDirection;
}

A_SScrollDirection A_SScrollDirectionInvertVertically(A_SScrollDirection scrollDirection) {
  if (scrollDirection == A_SScrollDirectionUp) {
    return A_SScrollDirectionDown;
  } else if (scrollDirection == A_SScrollDirectionDown) {
    return A_SScrollDirectionUp;
  }
  return scrollDirection;
}

A_SScrollDirection A_SScrollDirectionApplyTransform(A_SScrollDirection scrollDirection, CGAffineTransform transform) {
  if ((transform.a < 0) && A_SScrollDirectionContainsHorizontalDirection(scrollDirection)) {
    return A_SScrollDirectionInvertHorizontally(scrollDirection);
  } else if ((transform.d < 0) && A_SScrollDirectionContainsVerticalDirection(scrollDirection)) {
    return A_SScrollDirectionInvertVertically(scrollDirection);
  }
  return scrollDirection;
}
