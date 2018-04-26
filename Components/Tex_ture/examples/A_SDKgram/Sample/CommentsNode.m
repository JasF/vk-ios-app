//
//  CommentsNode.m
//  Sample
//
//  Created by Hannah Troisi on 3/21/16.
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

#import "CommentsNode.h"

#define INTER_COMMENT_SPACING 5
#define NUM_COMMENTS_TO_SHOW  3

@implementation CommentsNode
{
  CommentFeedModel              *_commentFeed;
  NSMutableArray <A_STextNode *> *_commentNodes;
}

#pragma mark - Lifecycle

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.automaticallyManagesSubnodes = YES;

    _commentNodes = [[NSMutableArray alloc] init];
  }
  return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  return [A_SStackLayoutSpec
          stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
          spacing:INTER_COMMENT_SPACING
          justifyContent:A_SStackLayoutJustifyContentStart
          alignItems:A_SStackLayoutAlignItemsStretch
          children:[_commentNodes copy]];
}

#pragma mark - Instance Methods

- (void)updateWithCommentFeedModel:(CommentFeedModel *)feed
{
  _commentFeed = feed;
  [_commentNodes removeAllObjects];
  
  if (_commentFeed) {
    [self createCommentLabels];
    
    BOOL addViewAllCommentsLabel = [feed numberOfCommentsForPhotoExceedsInteger:NUM_COMMENTS_TO_SHOW];
    NSAttributedString *commentLabelString;
    int labelsIndex = 0;
    
    if (addViewAllCommentsLabel) {
      commentLabelString         = [_commentFeed viewAllCommentsAttributedString];
      [_commentNodes[labelsIndex] setAttributedText:commentLabelString];
      labelsIndex++;
    }
    
    NSUInteger numCommentsInFeed = [_commentFeed numberOfItemsInFeed];
    
    for (int feedIndex = 0; feedIndex < numCommentsInFeed; feedIndex++) {
      commentLabelString         = [[_commentFeed objectAtIndex:feedIndex] commentAttributedString];
      [_commentNodes[labelsIndex] setAttributedText:commentLabelString];
      labelsIndex++;
    }
    
    [self setNeedsLayout];
  }
}


#pragma mark - Helper Methods

- (void)createCommentLabels
{
  BOOL addViewAllCommentsLabel = [_commentFeed numberOfCommentsForPhotoExceedsInteger:NUM_COMMENTS_TO_SHOW];
  NSUInteger numCommentsInFeed = [_commentFeed numberOfItemsInFeed];
  
  NSUInteger numLabelsToAdd    = (addViewAllCommentsLabel) ? numCommentsInFeed + 1 : numCommentsInFeed;
  
  for (NSUInteger i = 0; i < numLabelsToAdd; i++) {
    
    A_STextNode *commentLabel   = [[A_STextNode alloc] init];
    commentLabel.layerBacked = YES;
    commentLabel.maximumNumberOfLines = 3;
    
    [_commentNodes addObject:commentLabel];
  }
}

@end
