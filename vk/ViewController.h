//
//  ViewController.h
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

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "VKSdkManager.h"
#import "PythonBridge.h"

@protocol AuthorizationHandlerProtocolDelegate <NSObject>
- (void)accessTokenGathered:(NSString *)accessToken;
@end

@protocol AuthorizationHandlerProtocol <NSObject>
- (NSString *)receivedWall:(NSDictionary *)wall;
@end


@interface ViewController : ASViewController
@property (strong, nonatomic) id<AuthorizationHandlerProtocolDelegate> handler;
@property (strong, nonatomic) id<VKSdkManager> vkManager;
@property (strong, nonatomic) id<PythonBridge> pythonBridge;
@end
