//
//  OverviewA_SPagerNode.m
//  Sample
//
//  Created by Michael Schneider on 4/17/16.
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

#import "OverviewA_SPagerNode.h"

#pragma mark - Helper

static UIColor *OverViewA_SPagerNodeRandomColor() {
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}


#pragma mark - OverviewA_SPageNode

@interface OverviewA_SPageNode : A_SCellNode @end

@implementation OverviewA_SPageNode

- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
{
    return [A_SLayout layoutWithLayoutElement:self size:constrainedSize.max];
}

@end


#pragma mark - OverviewA_SPagerNode

@interface OverviewA_SPagerNode () <A_SPagerDataSource, A_SPagerDelegate>
@property (nonatomic, strong) A_SPagerNode *node;
@property (nonatomic, copy) NSArray *data;
@end

@implementation OverviewA_SPagerNode

- (instancetype)init
{
    self = [super init];
    if (self == nil) { return self; }
    
    _node = [A_SPagerNode new];
    _node.dataSource = self;
    _node.delegate = self;
    [self addSubnode:_node];
    
    return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
    // 100% of container
    _node.style.width = A_SDimensionMakeWithFraction(1.0);
    _node.style.height = A_SDimensionMakeWithFraction(1.0);
    return [A_SWrapperLayoutSpec wrapperWithLayoutElement:_node];
}

- (NSInteger)numberOfPagesInPagerNode:(A_SPagerNode *)pagerNode
{
    return 4;
}

- (A_SCellNodeBlock)pagerNode:(A_SPagerNode *)pagerNode nodeBlockAtIndex:(NSInteger)index
{
    return ^{
        A_SCellNode *cellNode = [OverviewA_SPageNode new];
        cellNode.backgroundColor = OverViewA_SPagerNodeRandomColor();
        return cellNode;
    };
}


@end
