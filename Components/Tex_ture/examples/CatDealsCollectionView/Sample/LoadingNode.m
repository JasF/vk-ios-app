//
//  LoadingNode.m
//  Sample
//
//  Created by Samuel Stow on 1/9/16.
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//
//  THE SOFTWARE IS PROVIDED "A_S IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "LoadingNode.h"
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>
#import <Async_DisplayKit/A_SHighlightOverlayLayer.h>

#import <Async_DisplayKit/A_SInsetLayoutSpec.h>
#import <Async_DisplayKit/A_SCenterLayoutSpec.h>

@interface LoadingNode ()
{
  A_SDisplayNode *_loadingSpinner;
}

@end

@implementation LoadingNode


#pragma mark -
#pragma mark A_SCellNode.

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
