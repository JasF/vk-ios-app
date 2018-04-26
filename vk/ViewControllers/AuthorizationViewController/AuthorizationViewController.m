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

@interface AuthorizationViewController ()
@property id<AuthorizationViewModel> viewModel;
@end

#pragma mark - Lifecycle

@implementation AuthorizationViewController
- (id)initWithViewModel:(id<AuthorizationViewModel>)viewModel
{
    NSCParameterAssert(viewModel);
    if (self = [super init]) {
        self.viewModel = viewModel;
        self.title = @"Authorization";
    }
  
    return self;
}
    
- (void)viewDidLoad {
    [super viewDidLoad];
    self.viewModel.viewController = self;
}
    
@end
