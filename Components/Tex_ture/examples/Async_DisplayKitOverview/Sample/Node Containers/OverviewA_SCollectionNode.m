//
//  OverviewA_SCollectionNode.m
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

#import "OverviewA_SCollectionNode.h"

#import <Async_DisplayKit/Async_DisplayKit.h>

@interface OverviewA_SCollectionNode () <A_SCollectionDataSource, A_SCollectionDelegate>
@property (nonatomic, strong) A_SCollectionNode *node;
@end

@implementation OverviewA_SCollectionNode

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self == nil) { return self; }
    
    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    _node = [[A_SCollectionNode alloc] initWithCollectionViewLayout:flowLayout];
    _node.dataSource = self;
    _node.delegate = self;
    [self addSubnode:_node];;
    
    return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
    // 100% of container
    _node.style.width = A_SDimensionMakeWithFraction(1.0);
    _node.style.height = A_SDimensionMakeWithFraction(1.0);
    return [A_SWrapperLayoutSpec wrapperWithLayoutElement:_node];
}

#pragma mark - <A_SCollectionDataSource, A_SCollectionDelegate>

- (NSInteger)collectionNode:(A_SCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
    return 100;
}

- (A_SCellNodeBlock)collectionNode:(A_SCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return ^{
        A_STextCellNode *cellNode = [A_STextCellNode new];
        cellNode.backgroundColor = [UIColor lightGrayColor];
        cellNode.text = [NSString stringWithFormat:@"Row: %ld", indexPath.row];
        return cellNode;
    };
}

- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return A_SSizeRangeMake(CGSizeMake(100, 100));
}

@end
