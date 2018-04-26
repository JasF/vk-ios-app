//
//  CommentsNode.m
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

#import "CommentsNode.h"
#import "TextStyles.h"

@interface CommentsNode ()
@property (nonatomic, strong) A_SImageNode *iconNode;
@property (nonatomic, strong) A_STextNode *countNode;
@property (nonatomic, assign) NSInteger commentsCount;
@end

@implementation CommentsNode

- (instancetype)initWithCommentsCount:(NSInteger)comentsCount
{
    self = [super init];
    if (self) {
        _commentsCount = comentsCount;
        
        _iconNode = [[A_SImageNode alloc] init];
        _iconNode.image = [UIImage imageNamed:@"icon_comment.png"];
        [self addSubnode:_iconNode];
        
        _countNode = [[A_STextNode alloc] init];
        if (_commentsCount > 0) {
           _countNode.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%zd", _commentsCount] attributes:[TextStyles cellControlStyle]];
        }
        [self addSubnode:_countNode];
        
        // make it tappable easily
        self.hitTestSlop = UIEdgeInsetsMake(-10, -10, -10, -10);
    }
    
    return self;
    
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
    A_SStackLayoutSpec *mainStack =
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
     spacing:6.0
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsCenter
     children:@[_iconNode, _countNode]];
    
    // Adjust size
    mainStack.style.minWidth = A_SDimensionMakeWithPoints(60.0);
    mainStack.style.maxHeight = A_SDimensionMakeWithPoints(40.0);
    
    return mainStack;
}

@end
