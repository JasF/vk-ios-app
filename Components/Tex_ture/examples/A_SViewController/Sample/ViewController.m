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

#import "DetailViewController.h"


@interface ViewController () <A_STableDataSource, A_STableDelegate>

@property (nonatomic, copy) NSArray *imageCategories;
@property (nonatomic, strong, readonly) A_STableNode *tableNode;

@end


@implementation ViewController

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super initWithNode:[A_STableNode new]];
    if (self == nil) { return self; }
    
    _imageCategories = @[@"abstract", @"animals", @"business", @"cats", @"city", @"food", @"nightlife", @"fashion", @"people", @"nature", @"sports", @"technics", @"transport"];
    
    return self;
}

- (void)dealloc
{
    self.node.delegate = nil;
    self.node.dataSource = nil;
}


#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Image Categories";
    
    self.node.delegate = self;
    self.node.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.node deselectRowAtIndexPath:self.node.indexPathForSelectedRow animated:YES];
}


#pragma mark - A_STableDataSource / A_STableDelegate

- (NSInteger)tableNode:(A_STableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
    return self.imageCategories.count;
}

- (A_SCellNodeBlock)tableNode:(A_STableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // As the block is executed on a background thread we need to cache the image category string outside
    NSString *imageCategory = self.imageCategories[indexPath.row];
    return ^{
        A_STextCellNode *textCellNode = [A_STextCellNode new];
        textCellNode.text = [imageCategory capitalizedString];
        return textCellNode;
    };
}

- (void)tableNode:(A_STableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *imageCategory = self.imageCategories[indexPath.row];
    DetailRootNode *detailRootNode = [[DetailRootNode alloc] initWithImageCategory:imageCategory];
    DetailViewController *detailViewController = [[DetailViewController alloc] initWithNode:detailRootNode];
    detailViewController.title = [imageCategory capitalizedString];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

@end
