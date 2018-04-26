//
//  DetailRootNode.m
//  Sample
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

#import "DetailRootNode.h"
#import "DetailCellNode.h"

#import <Async_DisplayKit/Async_DisplayKit.h>

static const NSInteger kImageHeight = 200;


@interface DetailRootNode () <A_SCollectionDataSource, A_SCollectionDelegate>

@property (nonatomic, copy) NSString *imageCategory;
@property (nonatomic, strong) A_SCollectionNode *collectionNode;

@end


@implementation DetailRootNode

#pragma mark - Lifecycle

- (instancetype)initWithImageCategory:(NSString *)imageCategory
{
    self = [super init];
    if (self) {
        // Enable automaticallyManagesSubnodes so the first time the layout pass of the node is happening all nodes that are referenced
        // in the laaout specification within layoutSpecThatFits: will be added automatically
        self.automaticallyManagesSubnodes = YES;
        
        _imageCategory = imageCategory;

        // Create A_SCollectionView. We don't have to add it explicitly as subnode as we will set usesImplicitHierarchyManagement to YES
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        _collectionNode = [[A_SCollectionNode alloc] initWithCollectionViewLayout:layout];
        _collectionNode.delegate = self;
        _collectionNode.dataSource = self;
        _collectionNode.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

- (void)dealloc
{
    _collectionNode.delegate = nil;
    _collectionNode.dataSource = nil;
}

#pragma mark - A_SDisplayNode

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
    return [A_SWrapperLayoutSpec wrapperWithLayoutElement:self.collectionNode];
}

#pragma mark - A_SCollectionDataSource

- (NSInteger)collectionNode:(A_SCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
    return 10;
}

- (A_SCellNodeBlock)collectionNode:(A_SCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *imageCategory = self.imageCategory;
    return ^{
        DetailCellNode *node = [[DetailCellNode alloc] init];
        node.row = indexPath.row;
        node.imageCategory = imageCategory;
        return node;
    };
}

- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize imageSize = CGSizeMake(CGRectGetWidth(collectionNode.view.frame), kImageHeight);
    return A_SSizeRangeMake(imageSize, imageSize);
}

@end
