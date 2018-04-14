//
//  TailLoadingNode.m
//  Sample
//
//  Created by Adlai Holler on 1/3/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "TailLoadingNode.h"

@interface TailLoadingNode ()
@property (nonatomic, strong) A_SDisplayNode *activityIndicatorNode;
@end

@implementation TailLoadingNode

- (instancetype)init
{
  if (self = [super init]) {
    _activityIndicatorNode = [[A_SDisplayNode alloc] initWithViewBlock:^{
      UIActivityIndicatorView *v = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
      [v startAnimating];
      return v;
    }];
    self.style.height = A_SDimensionMake(100);
  }
  return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  return [A_SCenterLayoutSpec centerLayoutSpecWithCenteringOptions:A_SCenterLayoutSpecCenteringXY sizingOptions:A_SCenterLayoutSpecSizingOptionMinimumXY child:self.activityIndicatorNode];
}

@end
