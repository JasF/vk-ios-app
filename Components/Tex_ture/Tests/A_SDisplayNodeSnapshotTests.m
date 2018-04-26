//
//  A_SDisplayNodeSnapshotTests.m
//  Tex_ture
//
//  Created by Adlai Holler on 8/16/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "A_SSnapshotTestCase.h"
#import <Async_DisplayKit/Async_DisplayKit.h>

@interface A_SDisplayNodeSnapshotTests : A_SSnapshotTestCase

@end

@implementation A_SDisplayNodeSnapshotTests

- (void)testBasicHierarchySnapshotTesting
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.backgroundColor = [UIColor blueColor];
  
  A_STextNode *subnode = [[A_STextNode alloc] init];
  subnode.backgroundColor = [UIColor whiteColor];
  
  subnode.attributedText = [[NSAttributedString alloc] initWithString:@"Hello"];
  node.automaticallyManagesSubnodes = YES;
  node.layoutSpecBlock = ^(A_SDisplayNode * _Nonnull node, A_SSizeRange constrainedSize) {
    return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(5, 5, 5, 5) child:subnode];
  };

  A_SDisplayNodeSizeToFitSizeRange(node, A_SSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY)));
  A_SSnapshotVerifyNode(node, nil);
}

@end
