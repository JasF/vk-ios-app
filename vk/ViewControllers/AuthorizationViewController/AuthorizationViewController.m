//
//  ViewController.m
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

#import "AuthorizationViewController.h"
#import "vk-Swift.h"

@interface AuthorizationViewController ()
@property id<AuthorizationViewModel> viewModel;
@property AuthorizationNode *authorizationNode;
@end

#pragma mark - Lifecycle

@implementation AuthorizationViewController
- (id)initWithViewModel:(id<AuthorizationViewModel>)viewModel
{
    NSCParameterAssert(viewModel);
    AuthorizationNode *node = [[AuthorizationNode alloc] init:[viewModel isAuthorizationOverAppAvailable]];
    if (self = [super initWithNode:node]) {
        _authorizationNode = node;
        _viewModel = viewModel;
    }
    return self;
}

- (void)dealloc {
    
}
    
- (void)viewDidLoad {
    [super viewDidLoad];
    self.viewModel.viewController = self;
    
    @weakify(self);
    self.authorizationNode.authorizeByAppHandler = ^{
        @strongify(self);
        [self.viewModel authorizeByApp];
    };
    self.authorizationNode.authorizeByLoginHandler = ^{
        @strongify(self);
        [self.viewModel authorizeByLogin];
    };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}
    
@end
