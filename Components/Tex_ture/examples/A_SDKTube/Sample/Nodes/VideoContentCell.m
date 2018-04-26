//
//  VideoContentCell.m
//  Sample
//
//  Created by Erekle on 5/14/16.
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

#import "VideoContentCell.h"

#import <Async_DisplayKit/A_SVideoPlayerNode.h>

#import "Utilities.h"

#define AVATAR_IMAGE_HEIGHT     30
#define HORIZONTAL_BUFFER       10
#define VERTICAL_BUFFER         5

@interface VideoContentCell () <A_SVideoPlayerNodeDelegate>

@end

@implementation VideoContentCell
{
  VideoModel *_videoModel;
  A_STextNode *_titleNode;
  A_SNetworkImageNode *_avatarNode;
  A_SVideoPlayerNode *_videoPlayerNode;
  A_SControlNode *_likeButtonNode;
  A_SButtonNode *_muteButtonNode;
}

- (instancetype)initWithVideoObject:(VideoModel *)video
{
  self = [super init];
  if (self) {
    _videoModel = video;

    _titleNode = [[A_STextNode alloc] init];
    _titleNode.attributedText = [[NSAttributedString alloc] initWithString:_videoModel.title attributes:[self titleNodeStringOptions]];
    _titleNode.style.flexGrow = 1.0;
    [self addSubnode:_titleNode];

    _avatarNode = [[A_SNetworkImageNode alloc] init];
    _avatarNode.URL = _videoModel.avatarUrl;

    [_avatarNode setImageModificationBlock:^UIImage *(UIImage *image) {
      CGSize profileImageSize = CGSizeMake(AVATAR_IMAGE_HEIGHT, AVATAR_IMAGE_HEIGHT);
      return [image makeCircularImageWithSize:profileImageSize];
    }];

    [self addSubnode:_avatarNode];

    _likeButtonNode = [[A_SControlNode alloc] init];
    _likeButtonNode.backgroundColor = [UIColor redColor];
    [self addSubnode:_likeButtonNode];

    _muteButtonNode = [[A_SButtonNode alloc] init];
    _muteButtonNode.style.width = A_SDimensionMakeWithPoints(16.0);
    _muteButtonNode.style.height = A_SDimensionMakeWithPoints(22.0);
    [_muteButtonNode addTarget:self action:@selector(didTapMuteButton) forControlEvents:A_SControlNodeEventTouchUpInside];

    _videoPlayerNode = [[A_SVideoPlayerNode alloc] initWithURL:_videoModel.url];
    _videoPlayerNode.delegate = self;
    _videoPlayerNode.backgroundColor = [UIColor blackColor];
    [self addSubnode:_videoPlayerNode];

    [self setMuteButtonIcon];
  }
  return self;
}

- (NSDictionary*)titleNodeStringOptions
{
  return @{
     NSFontAttributeName : [UIFont systemFontOfSize:14.0],
     NSForegroundColorAttributeName: [UIColor blackColor]
  };
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  CGFloat fullWidth = [UIScreen mainScreen].bounds.size.width;
  
  _videoPlayerNode.style.width = A_SDimensionMakeWithPoints(fullWidth);
  _videoPlayerNode.style.height = A_SDimensionMakeWithPoints(fullWidth * 9 / 16);
  
  _avatarNode.style.width = A_SDimensionMakeWithPoints(AVATAR_IMAGE_HEIGHT);
  _avatarNode.style.height = A_SDimensionMakeWithPoints(AVATAR_IMAGE_HEIGHT);
  
  _likeButtonNode.style.width = A_SDimensionMakeWithPoints(50.0);
  _likeButtonNode.style.height = A_SDimensionMakeWithPoints(26.0);

  A_SStackLayoutSpec *headerStack  = [A_SStackLayoutSpec horizontalStackLayoutSpec];
  headerStack.spacing = HORIZONTAL_BUFFER;
  headerStack.alignItems = A_SStackLayoutAlignItemsCenter;
  [headerStack setChildren:@[ _avatarNode, _titleNode]];

  UIEdgeInsets headerInsets      = UIEdgeInsetsMake(HORIZONTAL_BUFFER, HORIZONTAL_BUFFER, HORIZONTAL_BUFFER, HORIZONTAL_BUFFER);
  A_SInsetLayoutSpec *headerInset = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:headerInsets child:headerStack];

  A_SStackLayoutSpec *bottomControlsStack  = [A_SStackLayoutSpec horizontalStackLayoutSpec];
  bottomControlsStack.spacing = HORIZONTAL_BUFFER;
  bottomControlsStack.alignItems = A_SStackLayoutAlignItemsCenter;
  bottomControlsStack.children = @[_likeButtonNode];

  UIEdgeInsets bottomControlsInsets = UIEdgeInsetsMake(HORIZONTAL_BUFFER, HORIZONTAL_BUFFER, HORIZONTAL_BUFFER, HORIZONTAL_BUFFER);
  A_SInsetLayoutSpec *bottomControlsInset  = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:bottomControlsInsets child:bottomControlsStack];


  A_SStackLayoutSpec *verticalStack = [A_SStackLayoutSpec verticalStackLayoutSpec];
  verticalStack.alignItems = A_SStackLayoutAlignItemsStretch;
  verticalStack.children = @[headerInset, _videoPlayerNode, bottomControlsInset];
  return verticalStack;
}

- (void)setMuteButtonIcon
{
  if (_videoPlayerNode.muted) {
    [_muteButtonNode setImage:[UIImage imageNamed:@"ico-mute"] forState:UIControlStateNormal];
  } else {
    [_muteButtonNode setImage:[UIImage imageNamed:@"ico-unmute"] forState:UIControlStateNormal];
  }
}

- (void)didTapMuteButton
{
  _videoPlayerNode.muted = !_videoPlayerNode.muted;
  [self setMuteButtonIcon];
}

#pragma mark - A_SVideoPlayerNodeDelegate
- (void)didTapVideoPlayerNode:(A_SVideoPlayerNode *)videoPlayer
{
  if (_videoPlayerNode.playerState == A_SVideoNodePlayerStatePlaying) {
    _videoPlayerNode.controlsDisabled = !_videoPlayerNode.controlsDisabled;
    [_videoPlayerNode pause];
  } else {
    [_videoPlayerNode play];
  }
}

- (NSDictionary *)videoPlayerNodeCustomControls:(A_SVideoPlayerNode *)videoPlayer
{
  return @{
    @"muteControl" : _muteButtonNode
  };
}

- (NSArray *)controlsForControlBar:(NSDictionary *)availableControls
{
  NSMutableArray *controls = [[NSMutableArray alloc] init];

  if (availableControls[ @(A_SVideoPlayerNodeControlTypePlaybackButton) ]) {
    [controls addObject:availableControls[ @(A_SVideoPlayerNodeControlTypePlaybackButton) ]];
  }

  if (availableControls[ @(A_SVideoPlayerNodeControlTypeElapsedText) ]) {
    [controls addObject:availableControls[ @(A_SVideoPlayerNodeControlTypeElapsedText) ]];
  }

  if (availableControls[ @(A_SVideoPlayerNodeControlTypeScrubber) ]) {
    [controls addObject:availableControls[ @(A_SVideoPlayerNodeControlTypeScrubber) ]];
  }

  if (availableControls[ @(A_SVideoPlayerNodeControlTypeDurationText) ]) {
    [controls addObject:availableControls[ @(A_SVideoPlayerNodeControlTypeDurationText) ]];
  }

  return controls;
}

#pragma mark - Layout
- (A_SLayoutSpec*)videoPlayerNodeLayoutSpec:(A_SVideoPlayerNode *)videoPlayer forControls:(NSDictionary *)controls forMaximumSize:(CGSize)maxSize
{
  A_SLayoutSpec *spacer = [[A_SLayoutSpec alloc] init];
  spacer.style.flexGrow = 1.0;

  UIEdgeInsets insets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);

  if (controls[ @(A_SVideoPlayerNodeControlTypeScrubber) ]) {
    A_SDisplayNode *scrubber = controls[ @(A_SVideoPlayerNodeControlTypeScrubber) ];
    scrubber.style.height = A_SDimensionMakeWithPoints(44.0);
    scrubber.style.minWidth = A_SDimensionMakeWithPoints(0.0);
    scrubber.style.maxWidth = A_SDimensionMakeWithPoints(maxSize.width);
    scrubber.style.flexGrow = 1.0;
  }

  NSArray *controlBarControls = [self controlsForControlBar:controls];
  NSMutableArray *topBarControls = [[NSMutableArray alloc] init];

  //Our custom control
  if (controls[@"muteControl"]) {
    [topBarControls addObject:controls[@"muteControl"]];
  }


  A_SStackLayoutSpec *topBarSpec = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
                                                                          spacing:10.0
                                                                   justifyContent:A_SStackLayoutJustifyContentStart
                                                                       alignItems:A_SStackLayoutAlignItemsCenter
                                                                         children:topBarControls];

  A_SInsetLayoutSpec *topBarInsetSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:insets child:topBarSpec];

  A_SStackLayoutSpec *controlbarSpec = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
                                                                              spacing:10.0
                                                                       justifyContent:A_SStackLayoutJustifyContentStart
                                                                           alignItems:A_SStackLayoutAlignItemsCenter
                                                                             children: controlBarControls ];
  controlbarSpec.style.alignSelf = A_SStackLayoutAlignSelfStretch;



  A_SInsetLayoutSpec *controlbarInsetSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:insets child:controlbarSpec];

  controlbarInsetSpec.style.alignSelf = A_SStackLayoutAlignSelfStretch;

  A_SStackLayoutSpec *mainVerticalStack = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
                                                                                 spacing:0.0
                                                                          justifyContent:A_SStackLayoutJustifyContentStart
                                                                              alignItems:A_SStackLayoutAlignItemsStart
                                                                                children:@[topBarInsetSpec, spacer, controlbarInsetSpec]];

  return mainVerticalStack;

}
@end
