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
#import <Async_DisplayKit/A_SAssert.h>

#import "BlurbNode.h"
#import "NicCageNode.h"
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>

static const NSInteger kCageSize = 20;            // intial number of Cage cells in A_STableView
static const NSInteger kCageBatchSize = 10;       // number of Cage cells to add to A_STableView
static const NSInteger kMaxCageSize = 100;        // max number of Cage cells allowed in A_STableView

@interface ViewController () <A_STableViewDataSource, A_STableViewDelegate>
{
  A_STableView *_tableView;

  // array of boxed CGSizes corresponding to placekitten.com kittens
  NSMutableArray *_kittenDataSource;

  BOOL _dataSourceLocked;
  NSIndexPath *_blurbNodeIndexPath;
}

@property (nonatomic, strong) NSMutableArray *kittenDataSource;
@property (atomic, assign) BOOL dataSourceLocked;

@end

@implementation ViewController

#pragma mark -
#pragma mark UIViewController.

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;

  _tableView = [[A_STableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
  _tableView.separatorStyle = UITableViewCellSeparatorStyleNone; // KittenNode has its own separator
  _tableView.asyncDataSource = self;
  _tableView.asyncDelegate = self;

  // populate our "data source" with some random kittens
  _kittenDataSource = [self createLitterWithSize:kCageSize];

  _blurbNodeIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
  
  self.title = @"Nic Cage";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                         target:self
                                                                                         action:@selector(toggleEditingMode)];

  return self;
}

- (NSMutableArray *)createLitterWithSize:(NSInteger)litterSize
{
  NSMutableArray *cages = [NSMutableArray arrayWithCapacity:litterSize];
  for (NSInteger i = 0; i < litterSize; i++) {
      
    u_int32_t deltaX = arc4random_uniform(10) - 5;
    u_int32_t deltaY = arc4random_uniform(10) - 5;
    CGSize size = CGSizeMake(350 + 2 * deltaX, 350 + 4 * deltaY);
      
    [cages addObject:[NSValue valueWithCGSize:size]];
  }
  return cages;
}

- (void)setKittenDataSource:(NSMutableArray *)kittenDataSource {
  A_SDisplayNodeAssert(!self.dataSourceLocked, @"Could not update data source when it is locked !");

  _kittenDataSource = kittenDataSource;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self.view addSubview:_tableView];
}

- (void)viewWillLayoutSubviews
{
  _tableView.frame = self.view.bounds;
}

- (void)toggleEditingMode
{
  [_tableView setEditing:!_tableView.editing animated:YES];
}

#pragma mark -
#pragma mark A_STableView.

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [_tableView deselectRowAtIndexPath:indexPath animated:YES];
  // Assume only kitten nodes are selectable (see -tableView:shouldHighlightRowAtIndexPath:).
  NicCageNode *node = (NicCageNode *)[_tableView nodeForRowAtIndexPath:indexPath];
  [node toggleImageEnlargement];
}

- (A_SCellNode *)tableView:(A_STableView *)tableView nodeForRowAtIndexPath:(NSIndexPath *)indexPath
{
  // special-case the first row
  if ([_blurbNodeIndexPath compare:indexPath] == NSOrderedSame) {
    BlurbNode *node = [[BlurbNode alloc] init];
    return node;
  }

  NSValue *size = _kittenDataSource[indexPath.row - 1];
  NicCageNode *node = [[NicCageNode alloc] initWithKittenOfSize:size.CGSizeValue];
  return node;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  // blurb node + kLitterSize kitties
  return 1 + _kittenDataSource.count;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Enable selection for kitten nodes
  return [_blurbNodeIndexPath compare:indexPath] != NSOrderedSame;
}

- (void)tableViewLockDataSource:(A_STableView *)tableView
{
  self.dataSourceLocked = YES;
}

- (void)tableViewUnlockDataSource:(A_STableView *)tableView
{
  self.dataSourceLocked = NO;
}

- (BOOL)shouldBatchFetchForTableView:(UITableView *)tableView
{
  return _kittenDataSource.count < kMaxCageSize;
}

- (void)tableView:(UITableView *)tableView willBeginBatchFetchWithContext:(A_SBatchContext *)context
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    sleep(1);
    dispatch_async(dispatch_get_main_queue(), ^{
        
      // populate a new array of random-sized kittens
      NSArray *moarKittens = [self createLitterWithSize:kCageBatchSize];

      NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        
      // find number of kittens in the data source and create their indexPaths
      NSInteger existingRows = _kittenDataSource.count + 1;
        
      for (NSInteger i = 0; i < moarKittens.count; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:existingRows + i inSection:0]];
      }

      // add new kittens to the data source & notify table of new indexpaths
      [_kittenDataSource addObjectsFromArray:moarKittens];
      [tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];

      [context completeBatchFetching:YES];
    });
  });
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Enable editing for Kitten nodes
  return [_blurbNodeIndexPath compare:indexPath] != NSOrderedSame;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    // Assume only kitten nodes are editable (see -tableView:canEditRowAtIndexPath:).
    [_kittenDataSource removeObjectAtIndex:indexPath.row - 1];
    [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

@end
