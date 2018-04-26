//
//  TableViewController.m
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

#import "TableViewController.h"
#import "KittenNode.h"

@interface TableViewController () <A_STableViewDataSource, A_STableViewDelegate>
@property (nonatomic, strong) A_STableNode *tableNode;
@end

@implementation TableViewController

- (instancetype)init
{
  A_STableNode *tableNode = [[A_STableNode alloc] init];
  if (!(self = [super initWithNode:tableNode]))
    return nil;
  
  _tableNode = tableNode;
  tableNode.delegate = self;
  tableNode.dataSource = self;
  self.title = @"Table Node";
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.tableNode.view.contentInset = UIEdgeInsetsMake(CGRectGetHeight([[UIApplication sharedApplication] statusBarFrame]), 0, CGRectGetHeight(self.tabBarController.tabBar.frame), 0);
}

#pragma mark -
#pragma mark A_STableView.

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (A_SCellNode *)tableView:(A_STableView *)tableView nodeForRowAtIndexPath:(NSIndexPath *)indexPath
{
  KittenNode *cell = [[KittenNode alloc] init];
  cell.imageTappedBlock = ^{
    [KittenNode defaultImageTappedAction:self];
  };
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return 15;
}

@end
