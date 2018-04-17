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

#import "ViewController.h"
#import "Post.h"
#import "PostNode.h"
#import "VKSdkManager.h"
#import <VK-ios-sdk/VKSdk.h>
#import "WallPost.h"

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASAssert.h>

#include <stdlib.h>

@interface ViewController () <ASTableDataSource, ASTableDelegate>

@property (nonatomic, strong) ASTableNode *tableNode;
@property (nonatomic, strong) NSMutableArray *socialAppDataSource;

@end

#pragma mark - Lifecycle

@implementation ViewController

- (instancetype)init
{
    _tableNode = [[ASTableNode alloc] initWithStyle:UITableViewStylePlain];
  
    self = [super initWithNode:_tableNode];
  
    if (self) {
    
        _tableNode.delegate = self;
        _tableNode.dataSource = self;
        _tableNode.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      
        self.title = @"Authorization";

        [self createSocialAppDataSource];
    }
  
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
  
    // SocialAppNode has its own separator
    self.tableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    
    self.handler = [self.pythonBridge handlerWithProtocol:@protocol(AuthorizationHandlerProtocol)];
    [_pythonBridge setClassHandler:self name:@"AuthorizationHandlerProtocol"];
    [self initializeVkSdkManager];
    dispatch_async(dispatch_get_main_queue(), ^{
#ifdef DEBUG
        VKAccessToken *token = [VKAccessToken tokenWithToken:@"5707d7a0a400d18395446787aa77fb32a37cfb8e33c153fad544f09979685055a9d4ffe6a488b72447f6e"
                                                      secret:@""
                                                      userId:@""];
        self.vkManager.getTokenSuccess(token);
#else
        
        VKAccessToken *token = [VKAccessToken tokenWithToken:@"5707d7a0a400d18395446787aa77fb32a37cfb8e33c153fad544f09979685055a9d4ffe6a488b72447f6e"
                                                      secret:@""
                                                      userId:@""];
        self.vkManager.getTokenSuccess(token);
       // [self.vkManager authorize];
#endif
    });
    
}

#pragma mark - Data Model

- (void)createSocialAppDataSource
{
    _socialAppDataSource = [[NSMutableArray alloc] init];
}

#pragma mark - ASTableNode


- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Post *post = self.socialAppDataSource[indexPath.row];
    return ^{
        return [[PostNode alloc] initWithPost:post indexPath:indexPath];
    };
}

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
    return self.socialAppDataSource.count;
}


#pragma mark - Private Methods
- (void)initializeVkSdkManager {
    _vkManager.viewController = self;
    @weakify(self);
    _vkManager.getTokenSuccess = ^(VKAccessToken *token) {
        @strongify(self);
        dispatch_python(^{
            [self.handler accessTokenGathered:token.accessToken];
        });
    };
    _vkManager.getTokenFailed = ^(NSError *error, BOOL cancelled) {
        // @strongify(self);
        
    };
}

#pragma mark - AuthorizationHandlerProtocol
- (NSString *)receivedWall:(NSDictionary *)wall {
    return @"Done";
}


@end
