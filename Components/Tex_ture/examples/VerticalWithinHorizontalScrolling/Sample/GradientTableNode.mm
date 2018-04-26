//
//  GradientTableNode.mm
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

#import "GradientTableNode.h"
#import "RandomCoreGraphicsNode.h"
#import "AppDelegate.h"

#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>

#import <Async_DisplayKit/A_SStackLayoutSpec.h>
#import <Async_DisplayKit/A_SInsetLayoutSpec.h>


@interface GradientTableNode () <A_STableDelegate, A_STableDataSource>
{
  A_STableNode *_tableNode;
  CGSize _elementSize;
}

@end


@implementation GradientTableNode

- (instancetype)initWithElementSize:(CGSize)size
{
  if (!(self = [super init]))
    return nil;

  _elementSize = size;

  _tableNode = [[A_STableNode alloc] initWithStyle:UITableViewStylePlain];
  _tableNode.delegate = self;
  _tableNode.dataSource = self;
  
  A_SRangeTuningParameters rangeTuningParameters;
  rangeTuningParameters.leadingBufferScreenfuls = 1.0;
  rangeTuningParameters.trailingBufferScreenfuls = 0.5;
  [_tableNode setTuningParameters:rangeTuningParameters forRangeType:A_SLayoutRangeTypeDisplay];
  
  [self addSubnode:_tableNode];
  
  return self;
}

- (NSInteger)tableNode:(A_STableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
  return 100;
}

- (A_SCellNode *)tableNode:(A_STableNode *)tableNode nodeForRowAtIndexPath:(NSIndexPath *)indexPath
{
  RandomCoreGraphicsNode *elementNode = [[RandomCoreGraphicsNode alloc] init];
  elementNode.style.preferredSize = _elementSize;
  elementNode.indexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:_pageNumber];
  
  return elementNode;
}

- (void)tableNode:(A_STableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableNode deselectRowAtIndexPath:indexPath animated:NO];
  [_tableNode reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)layout
{
  [super layout];
  
  _tableNode.frame = self.bounds;
}

@end
