//
//  LikesNode.m
//  Sample
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "LikesNode.h"
#import "TextStyles.h"

@interface LikesNode ()
@property (nonatomic, strong) ASImageNode *iconNode;
@property (nonatomic, strong) ASTextNode *countNode;
@property (nonatomic, assign) NSInteger likesCount;
@property (nonatomic, assign) BOOL liked;
@end

@implementation LikesNode

- (instancetype)initWithLikesCount:(NSInteger)likesCount
                             liked:(BOOL)liked
{
    self = [super init];
    if (self) {
        _iconNode = [ASImageNode new];
        [self addSubnode:_iconNode];
        _countNode = [ASTextNode new];
        [self addSubnode:_countNode];
        [self setLikesCount:likesCount liked:liked];
    }
    return self;
    
}

- (void)setLikesCount:(NSInteger)likes liked:(BOOL)liked {
    _likesCount = likes;
    _liked = (_likesCount > 0) ? liked : NO;
    _iconNode.image = (_liked) ? [UIImage imageNamed:@"icon_liked.png"] : [UIImage imageNamed:@"icon_like.png"];
    if (_likesCount > 0) {
        NSDictionary *attributes = _liked ? [TextStyles cellControlColoredStyle] : [TextStyles cellControlStyle];
        _countNode.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)_likesCount] attributes:attributes];
    }
    [self setNeedsLayout];
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASStackLayoutSpec *mainStack = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                                                           spacing:6.0
                                                                    justifyContent:ASStackLayoutJustifyContentCenter
                                                                        alignItems:ASStackLayoutAlignItemsCenter
                                                                          children:@[_iconNode, _countNode]];
    return mainStack;
}

@end
