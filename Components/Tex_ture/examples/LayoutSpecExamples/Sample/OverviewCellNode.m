//
//  OverviewCellNode.m
//  Sample
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//

#import "OverviewCellNode.h"
#import "LayoutExampleNodes.h"
#import "Utilities.h"

@interface OverviewCellNode ()
@property (nonatomic, strong) A_STextNode *titleNode;
@property (nonatomic, strong) A_STextNode *descriptionNode;
@end

@implementation OverviewCellNode

- (instancetype)initWithLayoutExampleClass:(Class)layoutExampleClass
{
    self = [super init];
    if (self) {
      self.automaticallyManagesSubnodes = YES;
      
      _layoutExampleClass = layoutExampleClass;
      
      _titleNode = [[A_STextNode alloc] init];
      _titleNode.attributedText = [NSAttributedString attributedStringWithString:[layoutExampleClass title]
                                                                  fontSize:16
                                                                     color:[UIColor blackColor]];
  
      _descriptionNode = [[A_STextNode alloc] init];
      _descriptionNode.attributedText = [NSAttributedString attributedStringWithString:[layoutExampleClass descriptionTitle]
                                                                              fontSize:12
                                                                                 color:[UIColor lightGrayColor]];
   }
    return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
    A_SStackLayoutSpec *verticalStackSpec = [A_SStackLayoutSpec verticalStackLayoutSpec];
    verticalStackSpec.alignItems = A_SStackLayoutAlignItemsStart;
    verticalStackSpec.spacing = 5.0;
    verticalStackSpec.children = @[self.titleNode, self.descriptionNode];
    
    return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(10, 16, 10, 10) child:verticalStackSpec];
}

@end
