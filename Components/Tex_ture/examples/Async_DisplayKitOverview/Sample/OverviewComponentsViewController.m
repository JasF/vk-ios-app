//
//  OverviewComponentsViewController.m
//  Sample
//
//  Created by Michael Schneider on 4/15/16.
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

#import "OverviewComponentsViewController.h"

#import "OverviewDetailViewController.h"
#import "OverviewA_SCollectionNode.h"
#import "OverviewA_STableNode.h"
#import "OverviewA_SPagerNode.h"

#import <Async_DisplayKit/Async_DisplayKit.h>


#pragma mark - A_SCenterLayoutSpecSizeThatFitsBlock

typedef A_SLayoutSpec *(^OverviewDisplayNodeSizeThatFitsBlock)(A_SSizeRange constrainedSize);


#pragma mark - OverviewDisplayNodeWithSizeBlock

@interface OverviewDisplayNodeWithSizeBlock : A_SDisplayNode<A_SLayoutSpecListEntry>

@property (nonatomic, copy) NSString *entryTitle;
@property (nonatomic, copy) NSString *entryDescription;
@property (nonatomic, copy) OverviewDisplayNodeSizeThatFitsBlock sizeThatFitsBlock;

@end

@implementation OverviewDisplayNodeWithSizeBlock

// FIXME: Use new A_SDisplayNodeAPI (layoutSpecBlock) API if shipped
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
    OverviewDisplayNodeSizeThatFitsBlock block = self.sizeThatFitsBlock;
    if (block != nil) {
        return block(constrainedSize);
    }
    
    return [super layoutSpecThatFits:constrainedSize];
}

@end


#pragma mark - OverviewTitleDescriptionCellNode

@interface OverviewTitleDescriptionCellNode : A_SCellNode

@property (nonatomic, strong) A_STextNode *titleNode;
@property (nonatomic, strong) A_STextNode *descriptionNode;

@end

@implementation OverviewTitleDescriptionCellNode

- (instancetype)init
{
    self = [super init];
    if (self == nil) { return self; }
    
    _titleNode = [[A_STextNode alloc] init];
    _descriptionNode = [[A_STextNode alloc] init];
    
    [self addSubnode:_titleNode];
    [self addSubnode:_descriptionNode];
    
    return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
    BOOL hasDescription = self.descriptionNode.attributedText.length > 0;
    
    A_SStackLayoutSpec *verticalStackLayoutSpec = [A_SStackLayoutSpec verticalStackLayoutSpec];
    verticalStackLayoutSpec.alignItems = A_SStackLayoutAlignItemsStart;
    verticalStackLayoutSpec.spacing = 5.0;
    verticalStackLayoutSpec.children = hasDescription ? @[self.titleNode, self.descriptionNode] : @[self.titleNode];
    
    return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(10, 16, 10, 10) child:verticalStackLayoutSpec];
}

@end


#pragma mark - OverviewComponentsViewController

@interface OverviewComponentsViewController ()

@property (nonatomic, copy) NSArray *data;
@property (nonatomic, strong) A_STableNode *tableNode;

@end

@implementation OverviewComponentsViewController


#pragma mark - Lifecycle Methods

- (instancetype)init
{
  _tableNode = [A_STableNode new];
  
  self = [super initWithNode:_tableNode];
  
  if (self) {
    _tableNode.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableNode.delegate =  (id<A_STableDelegate>)self;
    _tableNode.dataSource = (id<A_STableDataSource>)self;
  }
  
  return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Async_DisplayKit";
    
    [self setupData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [_tableNode deselectRowAtIndexPath:_tableNode.indexPathForSelectedRow animated:YES];
}


#pragma mark - Data Model

- (void)setupData
{
    OverviewDisplayNodeWithSizeBlock *parentNode = nil;
    A_SDisplayNode *childNode = nil;

    
// Setup Nodes Container
// ---------------------------------------------------------------------------------------------------------
    NSMutableArray *mutableNodesContainerData = [NSMutableArray array];
    
#pragma mark A_SCollectionNode
    childNode = [OverviewA_SCollectionNode new];

    parentNode = [self centeringParentNodeWithInset:UIEdgeInsetsZero child:childNode];
    parentNode.entryTitle = @"A_SCollectionNode";
    parentNode.entryDescription = @"A_SCollectionNode is a node based class that wraps an A_SCollectionView. It can be used as a subnode of another node, and provide room for many (great) features and improvements later on.";
    [mutableNodesContainerData addObject:parentNode];
    
#pragma mark A_STableNode
    childNode = [OverviewA_STableNode new];
    
    parentNode = [self centeringParentNodeWithInset:UIEdgeInsetsZero child:childNode];
    parentNode.entryTitle = @"A_STableNode";
    parentNode.entryDescription = @"A_STableNode is a node based class that wraps an A_STableView. It can be used as a subnode of another node, and provide room for many (great) features and improvements later on.";
    [mutableNodesContainerData addObject:parentNode];
    
#pragma mark A_SPagerNode
    childNode = [OverviewA_SPagerNode new];
    
    parentNode = [self centeringParentNodeWithInset:UIEdgeInsetsZero child:childNode];
    parentNode.entryTitle = @"A_SPagerNode";
    parentNode.entryDescription = @"A_SPagerNode is a specialized subclass of A_SCollectionNode. Using it allows you to produce a page style UI similar to what you'd create with a UIPageViewController with UIKit. Luckily, the API is quite a bit simpler than UIPageViewController's.";
    [mutableNodesContainerData addObject:parentNode];
    
    
// Setup Nodes
// ---------------------------------------------------------------------------------------------------------
    NSMutableArray *mutableNodesData = [NSMutableArray array];

#pragma mark A_SDisplayNode
    A_SDisplayNode *displayNode = [self childNode];
    
    parentNode = [self centeringParentNodeWithChild:displayNode];
    parentNode.entryTitle = @"A_SDisplayNode";
    parentNode.entryDescription = @"A_SDisplayNode is the main view abstraction over UIView and CALayer. It initializes and owns a UIView in the same way UIViews create and own their own backing CALayers.";
    [mutableNodesData addObject:parentNode];
    
#pragma mark A_SButtonNode
    A_SButtonNode *buttonNode = [A_SButtonNode new];
    
    // Set title for button node with a given font or color. If you pass in nil for font or color the default system
    // font and black as color will be used
    [buttonNode setTitle:@"Button Title Normal" withFont:nil withColor:[UIColor blueColor] forState:UIControlStateNormal];
    [buttonNode setTitle:@"Button Title Highlighted" withFont:[UIFont systemFontOfSize:14] withColor:nil forState:UIControlStateHighlighted];
    [buttonNode addTarget:self action:@selector(buttonPressed:) forControlEvents:A_SControlNodeEventTouchUpInside];
    
    parentNode = [self centeringParentNodeWithChild:buttonNode];
    parentNode.entryTitle = @"A_SButtonNode";
    parentNode.entryDescription = @"A_SButtonNode (a subclass of A_SControlNode) supports simple buttons, with multiple states for a text label and an image with a few different layout options. Enables layerBacking for subnodes to significantly lighten main thread impact relative to UIButton (though async preparation is the bigger win).";
    [mutableNodesData addObject:parentNode];
    
#pragma mark A_STextNode
    A_STextNode *textNode = [A_STextNode new];
    textNode.attributedText = [[NSAttributedString alloc] initWithString:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum varius nisi quis mattis dignissim. Proin convallis odio nec ipsum molestie, in porta quam viverra. Fusce ornare dapibus velit, nec malesuada mauris pretium vitae. Etiam malesuada ligula magna."];
    
    parentNode = [self centeringParentNodeWithChild:textNode];
    parentNode.entryTitle = @"A_STextNode";
    parentNode.entryDescription = @"Like UITextView — built on TextKit with full-featured rich text support.";
    [mutableNodesData addObject:parentNode];
    
#pragma mark A_SEditableTextNode
    A_SEditableTextNode *editableTextNode = [A_SEditableTextNode new];
    editableTextNode.backgroundColor = [UIColor lightGrayColor];
    editableTextNode.attributedText = [[NSAttributedString alloc] initWithString:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum varius nisi quis mattis dignissim. Proin convallis odio nec ipsum molestie, in porta quam viverra. Fusce ornare dapibus velit, nec malesuada mauris pretium vitae. Etiam malesuada ligula magna."];
    
    parentNode = [self centeringParentNodeWithChild:editableTextNode];
    parentNode.entryTitle = @"A_SEditableTextNode";
    parentNode.entryDescription = @"A_SEditableTextNode provides a flexible, efficient, and animation-friendly editable text component.";
    [mutableNodesData addObject:parentNode];
    
#pragma mark A_SImageNode
    A_SImageNode *imageNode = [A_SImageNode new];
    imageNode.image = [UIImage imageNamed:@"image.jpg"];
    
    CGSize imageNetworkImageNodeSize = (CGSize){imageNode.image.size.width / 7, imageNode.image.size.height / 7};
    
    imageNode.style.preferredSize = imageNetworkImageNodeSize;
    
    parentNode = [self centeringParentNodeWithChild:imageNode];
    parentNode.entryTitle = @"A_SImageNode";
    parentNode.entryDescription = @"Like UIImageView — decodes images asynchronously.";
    [mutableNodesData addObject:parentNode];
    
#pragma mark A_SNetworkImageNode
    A_SNetworkImageNode *networkImageNode = [A_SNetworkImageNode new];
    networkImageNode.URL = [NSURL URLWithString:@"http://i.imgur.com/FjOR9kX.jpg"];
    networkImageNode.style.preferredSize = imageNetworkImageNodeSize;
    
    parentNode = [self centeringParentNodeWithChild:networkImageNode];
    parentNode.entryTitle = @"A_SNetworkImageNode";
    parentNode.entryDescription = @"A_SNetworkImageNode is a simple image node that can download and display an image from the network, with support for a placeholder image.";
    [mutableNodesData addObject:parentNode];
    
#pragma mark A_SMapNode
    A_SMapNode *mapNode = [A_SMapNode new];
    mapNode.style.preferredSize = CGSizeMake(300.0, 300.0);
    
    // San Francisco
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(37.7749, -122.4194);
    mapNode.region = MKCoordinateRegionMakeWithDistance(coord, 20000, 20000);
    
    parentNode = [self centeringParentNodeWithChild:mapNode];
    parentNode.entryTitle = @"A_SMapNode";
    parentNode.entryDescription = @"A_SMapNode offers completely asynchronous preparation, automatic preloading, and efficient memory handling. Its standard mode is a fully asynchronous snapshot, with liveMap mode loading automatically triggered by any A_STableView or A_SCollectionView; its .liveMap mode can be flipped on with ease (even on a background thread) to provide a cached, fully interactive map when necessary.";
    [mutableNodesData addObject:parentNode];
    
#pragma mark A_SVideoNode
    A_SVideoNode *videoNode = [A_SVideoNode new];
    videoNode.style.preferredSize = CGSizeMake(300.0, 400.0);
    
    AVAsset *asset = [AVAsset assetWithURL:[NSURL URLWithString:@"http://www.w3schools.com/html/mov_bbb.mp4"]];
    videoNode.asset = asset;
    
    parentNode = [self centeringParentNodeWithChild:videoNode];
    parentNode.entryTitle = @"A_SVideoNode";
    parentNode.entryDescription = @"A_SVideoNode is a newer class that exposes a relatively full-featured API, and is designed for both efficient and convenient implementation of embedded videos in scrolling views.";
    [mutableNodesData addObject:parentNode];
    
#pragma mark A_SScrollNode
    UIImage *scrollNodeImage = [UIImage imageNamed:@"image"];
    
    A_SScrollNode *scrollNode = [A_SScrollNode new];
    scrollNode.style.preferredSize = CGSizeMake(300.0, 400.0);
    
    UIScrollView *scrollNodeView = scrollNode.view;
    [scrollNodeView addSubview:[[UIImageView alloc] initWithImage:scrollNodeImage]];
    scrollNodeView.contentSize = scrollNodeImage.size;
    
    parentNode = [self centeringParentNodeWithChild:scrollNode];
    parentNode.entryTitle = @"A_SScrollNode";
    parentNode.entryDescription = @"Simple node that wraps UIScrollView.";
    [mutableNodesData addObject:parentNode];
    
    
// Layout Specs
// ---------------------------------------------------------------------------------------------------------
    NSMutableArray *mutableLayoutSpecData = [NSMutableArray array];
    
#pragma mark A_SInsetLayoutSpec
    childNode = [self childNode];
    
    parentNode = [self parentNodeWithChild:childNode];
    parentNode.entryTitle = @"A_SInsetLayoutSpec";
    parentNode.entryDescription = @"Applies an inset margin around a component.";
    parentNode.sizeThatFitsBlock = ^A_SLayoutSpec *(A_SSizeRange constrainedSize) {
        return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(20, 10, 0, 0) child:childNode];
    };
    [parentNode addSubnode:childNode];
    [mutableLayoutSpecData addObject:parentNode];
    

#pragma mark A_SBackgroundLayoutSpec
    A_SDisplayNode *backgroundNode = [A_SDisplayNode new];
    backgroundNode.backgroundColor = [UIColor greenColor];
    
    childNode = [self childNode];
    childNode.backgroundColor = [childNode.backgroundColor colorWithAlphaComponent:0.5];
    
    parentNode = [self parentNodeWithChild:childNode];
    parentNode.entryTitle = @"A_SBackgroundLayoutSpec";
    parentNode.entryDescription = @"Lays out a component, stretching another component behind it as a backdrop.";
    parentNode.sizeThatFitsBlock = ^A_SLayoutSpec *(A_SSizeRange constrainedSize) {
        return [A_SBackgroundLayoutSpec backgroundLayoutSpecWithChild:childNode background:backgroundNode];
    };
    [parentNode addSubnode:backgroundNode];
    [parentNode addSubnode:childNode];
    [mutableLayoutSpecData addObject:parentNode];
    

#pragma mark A_SOverlayLayoutSpec
    A_SDisplayNode *overlayNode = [A_SDisplayNode new];
    overlayNode.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.5];
    
    childNode = [self childNode];
    
    parentNode = [self parentNodeWithChild:childNode];
    parentNode.entryTitle = @"A_SOverlayLayoutSpec";
    parentNode.entryDescription = @"Lays out a component, stretching another component on top of it as an overlay.";
    parentNode.sizeThatFitsBlock = ^A_SLayoutSpec *(A_SSizeRange constrainedSize) {
        return [A_SOverlayLayoutSpec overlayLayoutSpecWithChild:childNode overlay:overlayNode];
    };
    [parentNode addSubnode:childNode];
    [parentNode addSubnode:overlayNode];
    [mutableLayoutSpecData addObject:parentNode];
    

#pragma mark A_SCenterLayoutSpec
    childNode = [self childNode];
    
    parentNode = [self parentNodeWithChild:childNode];
    parentNode.entryTitle = @"A_SCenterLayoutSpec";
    parentNode.entryDescription = @"Centers a component in the available space.";
    parentNode.sizeThatFitsBlock = ^A_SLayoutSpec *(A_SSizeRange constrainedSize) {
        return [A_SCenterLayoutSpec centerLayoutSpecWithCenteringOptions:A_SCenterLayoutSpecCenteringXY
                                                          sizingOptions:A_SCenterLayoutSpecSizingOptionDefault
                                                                  child:childNode];
    };
    [parentNode addSubnode:childNode];
    [mutableLayoutSpecData addObject:parentNode];

#pragma mark A_SRatioLayoutSpec
    childNode = [self childNode];
    
    parentNode = [self parentNodeWithChild:childNode];
    parentNode.entryTitle = @"A_SRatioLayoutSpec";
    parentNode.entryDescription = @"Lays out a component at a fixed aspect ratio. Great for images, gifs and videos.";
    parentNode.sizeThatFitsBlock = ^A_SLayoutSpec *(A_SSizeRange constrainedSize) {
        return [A_SRatioLayoutSpec ratioLayoutSpecWithRatio:0.25 child:childNode];
    };
    [parentNode addSubnode:childNode];
    [mutableLayoutSpecData addObject:parentNode];

#pragma mark A_SRelativeLayoutSpec
    childNode = [self childNode];
    
    parentNode = [self parentNodeWithChild:childNode];
    parentNode.entryTitle = @"A_SRelativeLayoutSpec";
    parentNode.entryDescription = @"Lays out a component and positions it within the layout bounds according to vertical and horizontal positional specifiers. Similar to the “9-part” image areas, a child can be positioned at any of the 4 corners, or the middle of any of the 4 edges, as well as the center.";
    parentNode.sizeThatFitsBlock = ^A_SLayoutSpec *(A_SSizeRange constrainedSize) {
        return [A_SRelativeLayoutSpec relativePositionLayoutSpecWithHorizontalPosition:A_SRelativeLayoutSpecPositionEnd
                                                                     verticalPosition:A_SRelativeLayoutSpecPositionCenter
                                                                         sizingOption:A_SRelativeLayoutSpecSizingOptionDefault
                                                                                child:childNode];
    };
    [parentNode addSubnode:childNode];
    [mutableLayoutSpecData addObject:parentNode];

#pragma mark A_SAbsoluteLayoutSpec
    childNode = [self childNode];
    // Add a layout position to the child node that the absolute layout spec will pick up and place it on that position
    childNode.style.layoutPosition = CGPointMake(10.0, 10.0);
    
    parentNode = [self parentNodeWithChild:childNode];
    parentNode.entryTitle = @"A_SAbsoluteLayoutSpec";
    parentNode.entryDescription = @"Allows positioning children at fixed offsets.";
    parentNode.sizeThatFitsBlock = ^A_SLayoutSpec *(A_SSizeRange constrainedSize) {
        return [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[childNode]];
    };
    [parentNode addSubnode:childNode];
    [mutableLayoutSpecData addObject:parentNode];
    

#pragma mark Vertical A_SStackLayoutSpec
    A_SDisplayNode *childNode1 = [self childNode];
    childNode1.backgroundColor = [UIColor greenColor];
    
    A_SDisplayNode *childNode2 = [self childNode];
    childNode2.backgroundColor = [UIColor blueColor];
    
    A_SDisplayNode *childNode3 = [self childNode];
    childNode3.backgroundColor = [UIColor yellowColor];
    
    // If we just would add the childrent to the stack layout the layout would be to tall and run out of the edge of
    // the node as 50+50+50 = 150 but the parent node is only 100 height. To prevent that we set flexShrink on 2 of the
    // children to let the stack layout know it should shrink these children in case the layout will run over the edge
    childNode2.style.flexShrink = 1.0;
    childNode3.style.flexShrink = 1.0;
    
    parentNode = [self parentNodeWithChild:childNode];
    parentNode.entryTitle = @"Vertical A_SStackLayoutSpec";
    parentNode.entryDescription = @"Is based on a simplified version of CSS flexbox. It allows you to stack components vertically or horizontally and specify how they should be flexed and aligned to fit in the available space.";
    parentNode.sizeThatFitsBlock = ^A_SLayoutSpec *(A_SSizeRange constrainedSize) {
        A_SStackLayoutSpec *verticalStackLayoutSpec = [A_SStackLayoutSpec verticalStackLayoutSpec];
        verticalStackLayoutSpec.alignItems = A_SStackLayoutAlignItemsStart;
        verticalStackLayoutSpec.children = @[childNode1, childNode2, childNode3];
        return verticalStackLayoutSpec;
    };
    [parentNode addSubnode:childNode1];
    [parentNode addSubnode:childNode2];
    [parentNode addSubnode:childNode3];
    [mutableLayoutSpecData addObject:parentNode];
    
#pragma mark Horizontal A_SStackLayoutSpec
    childNode1 = [A_SDisplayNode new];
    childNode1.style.preferredSize = CGSizeMake(10.0, 20.0);
    childNode1.style.flexGrow = 1.0;
    childNode1.backgroundColor = [UIColor greenColor];
    
    childNode2 = [A_SDisplayNode new];
    childNode2.style.preferredSize = CGSizeMake(10.0, 20.0);
    childNode2.style.alignSelf = A_SStackLayoutAlignSelfStretch;
    childNode2.backgroundColor = [UIColor blueColor];
    
    childNode3 = [A_SDisplayNode new];
    childNode3.style.preferredSize = CGSizeMake(10.0, 20.0);
    childNode3.backgroundColor = [UIColor yellowColor];
    
    parentNode = [self parentNodeWithChild:childNode];
    parentNode.entryTitle = @"Horizontal A_SStackLayoutSpec";
    parentNode.entryDescription = @"Is based on a simplified version of CSS flexbox. It allows you to stack components vertically or horizontally and specify how they should be flexed and aligned to fit in the available space.";
    parentNode.sizeThatFitsBlock = ^A_SLayoutSpec *(A_SSizeRange constrainedSize) {
        
        // Create stack alyout spec to layout children
        A_SStackLayoutSpec *horizontalStackSpec = [A_SStackLayoutSpec horizontalStackLayoutSpec];
        horizontalStackSpec.alignItems = A_SStackLayoutAlignItemsStart;
        horizontalStackSpec.children = @[childNode1, childNode2, childNode3];
        horizontalStackSpec.spacing = 5.0; // Spacing between children
        
        // Layout the stack layout with 100% width and 100% height of the parent node
        horizontalStackSpec.style.height = A_SDimensionMakeWithFraction(1.0);
        horizontalStackSpec.style.width = A_SDimensionMakeWithFraction(1.0);
        
        // Add a bit of inset
        return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(0.0, 5.0, 0.0, 5.0) child:horizontalStackSpec];
    };
    [parentNode addSubnode:childNode1];
    [parentNode addSubnode:childNode2];
    [parentNode addSubnode:childNode3];
    [mutableLayoutSpecData addObject:parentNode];
    

// Setup Data
// ---------------------------------------------------------------------------------------------------------
    NSMutableArray *mutableData = [NSMutableArray array];
    [mutableData addObject:@{@"title" : @"Node Containers", @"data" : mutableNodesContainerData}];
    [mutableData addObject:@{@"title" : @"Nodes", @"data" : mutableNodesData}];
    [mutableData addObject:@{@"title" : @"Layout Specs", @"data" : [mutableLayoutSpecData copy]}];
    self.data  = mutableData;
}

#pragma mark - Parent / Child Helper

- (OverviewDisplayNodeWithSizeBlock *)parentNodeWithChild:(A_SDisplayNode *)child
{
    OverviewDisplayNodeWithSizeBlock *parentNode = [OverviewDisplayNodeWithSizeBlock new];
    parentNode.style.preferredSize = CGSizeMake(100, 100);
    parentNode.backgroundColor = [UIColor redColor];
    return parentNode;
}

- (OverviewDisplayNodeWithSizeBlock *)centeringParentNodeWithChild:(A_SDisplayNode *)child
{
    return [self centeringParentNodeWithInset:UIEdgeInsetsMake(10, 10, 10, 10) child:child];
}

- (OverviewDisplayNodeWithSizeBlock *)centeringParentNodeWithInset:(UIEdgeInsets)insets child:(A_SDisplayNode *)child
{
    OverviewDisplayNodeWithSizeBlock *parentNode = [OverviewDisplayNodeWithSizeBlock new];
    [parentNode addSubnode:child];
    parentNode.sizeThatFitsBlock = ^A_SLayoutSpec *(A_SSizeRange constrainedSize) {
        A_SCenterLayoutSpec *centerLayoutSpec = [A_SCenterLayoutSpec centerLayoutSpecWithCenteringOptions:A_SCenterLayoutSpecCenteringXY sizingOptions:A_SCenterLayoutSpecSizingOptionDefault child:child];
        return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:insets child:centerLayoutSpec];
    };
    return parentNode;
}

- (A_SDisplayNode *)childNode
{
    A_SDisplayNode *childNode = [A_SDisplayNode new];
    childNode.style.preferredSize = CGSizeMake(50, 50);
    childNode.backgroundColor = [UIColor blueColor];
    return childNode;
}

#pragma mark - Actions

- (void)buttonPressed:(A_SButtonNode *)buttonNode
{
    NSLog(@"Button Pressed");
}

#pragma mark - <A_STableDataSource / A_STableDelegate>

- (NSInteger)numberOfSectionsInTableNode:(A_STableNode *)tableNode
{
    return self.data.count;
}

- (nullable NSString *)tableNode:(A_STableNode *)tableNode titleForHeaderInSection:(NSInteger)section
{
    return self.data[section][@"title"];
}

- (NSInteger)tableNode:(A_STableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
    return [self.data[section][@"data"] count];
}

- (A_SCellNodeBlock)tableNode:(A_STableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // You should get the node or data you want to pass to the cell node outside of the A_SCellNodeBlock
    A_SDisplayNode<A_SLayoutSpecListEntry> *node = self.data[indexPath.section][@"data"][indexPath.row];
    return ^{
        OverviewTitleDescriptionCellNode *cellNode = [OverviewTitleDescriptionCellNode new];
        
        NSDictionary *titleNodeAttributes = @{
            NSFontAttributeName : [UIFont boldSystemFontOfSize:14.0],
            NSForegroundColorAttributeName : [UIColor blackColor]
        };
        cellNode.titleNode.attributedText = [[NSAttributedString alloc] initWithString:node.entryTitle attributes:titleNodeAttributes];
        
        if (node.entryDescription) {
            NSDictionary *descriptionNodeAttributes = @{NSForegroundColorAttributeName : [UIColor lightGrayColor]};
            cellNode.descriptionNode.attributedText = [[NSAttributedString alloc] initWithString:node.entryDescription attributes:descriptionNodeAttributes];
        }
        
        return cellNode;
    };
}

- (void)tableNode:(A_STableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    A_SDisplayNode *node = self.data[indexPath.section][@"data"][indexPath.row];
    OverviewDetailViewController *detail = [[OverviewDetailViewController alloc] initWithNode:node];
    [self.navigationController pushViewController:detail animated:YES];
}

@end
