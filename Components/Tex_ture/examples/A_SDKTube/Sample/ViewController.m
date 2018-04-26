//
//  ViewController.m
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

#import "ViewController.h"
#import <Async_DisplayKit/Async_DisplayKit.h>
#import <Async_DisplayKit/A_SVideoPlayerNode.h>
#import "VideoModel.h"
#import "VideoContentCell.h"

@interface ViewController()<A_SVideoPlayerNodeDelegate, A_STableDelegate, A_STableDataSource>
@property (nonatomic, strong) A_SVideoPlayerNode *videoPlayerNode;
@end

@implementation ViewController
{
  A_STableNode *_tableNode;
  NSMutableArray<VideoModel*> *_videoFeedData;
}

- (instancetype)init
{
  _tableNode = [[A_STableNode alloc] init];
  _tableNode.delegate = self;
  _tableNode.dataSource = self;

  if (!(self = [super initWithNode:_tableNode])) {
    return nil;
  }
  
  return self;
}

- (void)loadView
{
  [super loadView];

  _videoFeedData = [[NSMutableArray alloc] initWithObjects:[[VideoModel alloc] init], [[VideoModel alloc] init], nil];

  [_tableNode reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  //[self.view addSubnode:self.videoPlayerNode];
  
  //[self.videoPlayerNode setNeedsLayout];
}

#pragma mark - A_SCollectionDelegate - A_SCollectionDataSource

- (NSInteger)numberOfSectionsInTableNode:(A_STableNode *)tableNode
{
  return 1;
}

- (NSInteger)tableNode:(A_STableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
  return _videoFeedData.count;
}

- (A_SCellNode *)tableNode:(A_STableNode *)tableNode nodeForRowAtIndexPath:(NSIndexPath *)indexPath
{
  VideoModel *videoObject = [_videoFeedData objectAtIndex:indexPath.row];
  VideoContentCell *cellNode = [[VideoContentCell alloc] initWithVideoObject:videoObject];
  return cellNode;
}

- (A_SVideoPlayerNode *)videoPlayerNode;
{
  if (_videoPlayerNode) {
    return _videoPlayerNode;
  }
  
  NSURL *fileUrl = [NSURL URLWithString:@"https://www.w3schools.com/html/mov_bbb.mp4"];

  _videoPlayerNode = [[A_SVideoPlayerNode alloc] initWithURL:fileUrl];
  _videoPlayerNode.delegate = self;
//  _videoPlayerNode.disableControls = YES;
//
//  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//    _videoPlayerNode.disableControls = NO;
//  });

  _videoPlayerNode.backgroundColor = [UIColor blackColor];

  return _videoPlayerNode;
}

#pragma mark - A_SVideoPlayerNodeDelegate
//- (NSArray *)videoPlayerNodeNeededControls:(A_SVideoPlayerNode *)videoPlayer
//{
//  return @[ @(A_SVideoPlayerNodeControlTypePlaybackButton),
//            @(A_SVideoPlayerNodeControlTypeElapsedText),
//            @(A_SVideoPlayerNodeControlTypeScrubber),
//            @(A_SVideoPlayerNodeControlTypeDurationText) ];
//}
//
//- (UIColor *)videoPlayerNodeScrubberMaximumTrackTint:(A_SVideoPlayerNode *)videoPlayer
//{
//  return [UIColor colorWithRed:1 green:1 blue:1 alpha:0.3];
//}
//
//- (UIColor *)videoPlayerNodeScrubberMinimumTrackTint:(A_SVideoPlayerNode *)videoPlayer
//{
//  return [UIColor whiteColor];
//}
//
//- (UIColor *)videoPlayerNodeScrubberThumbTint:(A_SVideoPlayerNode *)videoPlayer
//{
//  return [UIColor whiteColor];
//}
//
//- (NSDictionary *)videoPlayerNodeTimeLabelAttributes:(A_SVideoPlayerNode *)videoPlayerNode timeLabelType:(A_SVideoPlayerNodeControlType)timeLabelType
//{
//  NSDictionary *options;
//
//  if (timeLabelType == A_SVideoPlayerNodeControlTypeElapsedText) {
//    options = @{
//                NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Medium" size:16.0],
//                NSForegroundColorAttributeName: [UIColor orangeColor]
//                };
//  } else if (timeLabelType == A_SVideoPlayerNodeControlTypeDurationText) {
//    options = @{
//                NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Medium" size:16.0],
//                NSForegroundColorAttributeName: [UIColor redColor]
//                };
//  }
//
//  return options;
//}

/*- (A_SLayoutSpec *)videoPlayerNodeLayoutSpec:(A_SVideoPlayerNode *)videoPlayer
                                forControls:(NSDictionary *)controls
                         forConstrainedSize:(A_SSizeRange)constrainedSize
{

  NSMutableArray *bottomControls = [[NSMutableArray alloc] init];
  NSMutableArray *topControls = [[NSMutableArray alloc] init];

  A_SDisplayNode *scrubberNode = controls[@(A_SVideoPlayerNodeControlTypeScrubber)];
  A_SDisplayNode *playbackButtonNode = controls[@(A_SVideoPlayerNodeControlTypePlaybackButton)];
  A_STextNode *elapsedTexNode = controls[@(A_SVideoPlayerNodeControlTypeElapsedText)];
  A_STextNode *durationTexNode = controls[@(A_SVideoPlayerNodeControlTypeDurationText)];

  if (playbackButtonNode) {
    [bottomControls addObject:playbackButtonNode];
  }

  if (scrubberNode) {
    scrubberNode.preferredFrameSize = CGSizeMake(constrainedSize.max.width, 44.0);
    [bottomControls addObject:scrubberNode];
  }

  if (elapsedTexNode) {
    [topControls addObject:elapsedTexNode];
  }

  if (durationTexNode) {
    [topControls addObject:durationTexNode];
  }

  A_SLayoutSpec *spacer = [[A_SLayoutSpec alloc] init];
  spacer.flexGrow = 1.0;

  A_SStackLayoutSpec *topBarSpec = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
                                                                              spacing:10.0
                                                                       justifyContent:A_SStackLayoutJustifyContentCenter
                                                                           alignItems:A_SStackLayoutAlignItemsCenter
                                                                             children:topControls];



  UIEdgeInsets topBarSpecInsets = UIEdgeInsetsMake(20.0, 10.0, 0.0, 10.0);

  A_SInsetLayoutSpec *topBarSpecInsetSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:topBarSpecInsets child:topBarSpec];
  topBarSpecInsetSpec.alignSelf = A_SStackLayoutAlignSelfStretch;

  A_SStackLayoutSpec *controlbarSpec = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
                                                                              spacing:10.0
                                                                       justifyContent:A_SStackLayoutJustifyContentStart
                                                                           alignItems:A_SStackLayoutAlignItemsCenter
                                                                             children:bottomControls];
  controlbarSpec.alignSelf = A_SStackLayoutAlignSelfStretch;

  UIEdgeInsets insets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);

  A_SInsetLayoutSpec *controlbarInsetSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:insets child:controlbarSpec];

  controlbarInsetSpec.alignSelf = A_SStackLayoutAlignSelfStretch;

  A_SStackLayoutSpec *mainVerticalStack = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
                                                                                 spacing:0.0
                                                                          justifyContent:A_SStackLayoutJustifyContentStart
                                                                              alignItems:A_SStackLayoutAlignItemsStart
                                                                                children:@[ topBarSpecInsetSpec, spacer, controlbarInsetSpec ]];


  return mainVerticalStack;
}*/

@end
