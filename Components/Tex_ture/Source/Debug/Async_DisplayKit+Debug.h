//
//  Async_DisplayKit+Debug.h
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

#import <Async_DisplayKit/A_SControlNode.h>
#import <Async_DisplayKit/A_SImageNode.h>

NS_ASSUME_NONNULL_BEGIN

@interface A_SImageNode (Debugging)

/**
 * Enables an A_SImageNode debug label that shows the ratio of pixels in the source image to those in
 * the displayed bounds (including cropRect).  This helps detect excessive image fetching / downscaling,
 * as well as upscaling (such as providing a URL not suitable for a Retina device).  For dev purposes only.
 * Specify YES to show the label on all A_SImageNodes with non-1.0x source-to-bounds pixel ratio.
 */
@property (class, nonatomic) BOOL shouldShowImageScalingOverlay;

@end

@interface A_SControlNode (Debugging)

/**
 * Class method to enable a visualization overlay of the tappable area on the A_SControlNode. For app debugging purposes only.
 * NOTE: GESTURE RECOGNIZERS, (including tap gesture recognizers on a control node) WILL NOT BE VISUALIZED!!!
 * Overlay = translucent GREEN color,
 * edges that are clipped by the tappable area of any parent (their bounds + hitTestSlop) in the hierarchy = DARK GREEN BORDERED EDGE,
 * edges that are clipped by clipToBounds = YES of any parent in the hierarchy = ORANGE BORDERED EDGE (may still receive touches beyond
 * overlay rect, but can't be visualized).
 * Specify YES to make this debug feature enabled when messaging the A_SControlNode class.
 */
@property (class, nonatomic) BOOL enableHitTestDebug;

@end

@interface A_SDisplayNode (RangeDebugging)

/**
 * Enable a visualization overlay of the all table/collection tuning parameters. For dev purposes only.
 * To use, set this in the AppDelegate --> A_SDisplayNode.shouldShowRangeDebugOverlay = YES
 */
@property (class, nonatomic) BOOL shouldShowRangeDebugOverlay;

@end


NS_ASSUME_NONNULL_END
