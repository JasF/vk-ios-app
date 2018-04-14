//
//  PI_NRemoteImageCallbacks.m
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import "PI_NRemoteImageCallbacks.h"

@implementation PI_NRemoteImageCallbacks

- (instancetype)init
{
  if (self = [super init]) {
    _requestTime = CACurrentMediaTime();
  }
  return self;
}

@end
