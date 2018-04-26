//
//  OverrideViewController.m
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

#import "OverrideViewController.h"
#import <Async_DisplayKit/A_STraitCollection.h>

static NSString *kLinkAttributeName = @"PlaceKittenNodeLinkAttributeName";

@interface OverrideNode()
@property (nonatomic, strong) A_STextNode *textNode;
@property (nonatomic, strong) A_SButtonNode *buttonNode;
@end

@implementation OverrideNode

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;
  
  _textNode = [[A_STextNode alloc] init];
  _textNode.style.flexGrow = 1.0;
  _textNode.style.flexShrink = 1.0;
  _textNode.maximumNumberOfLines = 3;
  [self addSubnode:_textNode];
  
  _buttonNode = [[A_SButtonNode alloc] init];
  [_buttonNode setAttributedTitle:[[NSAttributedString alloc] initWithString:@"Close"] forState:UIControlStateNormal];
  [self addSubnode:_buttonNode];
  
  self.backgroundColor = [UIColor lightGrayColor];
  
  return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  CGFloat pointSize = 16.f;
  A_STraitCollection *traitCollection = [self asyncTraitCollection];
  if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
    // This should never happen because we override the VC's display traits to always be compact.
    pointSize = 100;
  }
  
  NSString *blurb = @"kittens courtesy placekitten.com";
  NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:blurb];
  [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue" size:pointSize] range:NSMakeRange(0, blurb.length)];
  [string addAttributes:@{
                          kLinkAttributeName: [NSURL URLWithString:@"http://placekitten.com/"],
                          NSForegroundColorAttributeName: [UIColor grayColor],
                          NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle | NSUnderlinePatternDot),
                          }
                  range:[blurb rangeOfString:@"placekitten.com"]];
  
  _textNode.attributedText = string;
  
  A_SStackLayoutSpec *stackSpec = [A_SStackLayoutSpec verticalStackLayoutSpec];
  stackSpec.children = @[_textNode, _buttonNode];
  stackSpec.spacing = 10;
  return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(40, 20, 20, 20) child:stackSpec];
}

@end

@interface OverrideViewController ()

@end

@implementation OverrideViewController

- (instancetype)init
{
  OverrideNode *overrideNode = [[OverrideNode alloc] init];
  
  if (!(self = [super initWithNode:overrideNode]))
    return nil;
  
  [overrideNode.buttonNode addTarget:self action:@selector(closeTapped:) forControlEvents:A_SControlNodeEventTouchUpInside];
  return self;
}

- (void)closeTapped:(id)sender
{
  if (self.closeBlock) {
    self.closeBlock();
  }
}

@end
