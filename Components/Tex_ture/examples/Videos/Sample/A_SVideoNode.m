//
//  A_SVideoNode.m
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


#import "A_SVideoNode.h"

@interface A_SVideoNode ()
@property (nonatomic) AVPlayer *player;
@end

@implementation A_SVideoNode

- (instancetype)initWithURL:(NSURL *)URL;
{
  return [self initWithURL:URL videoGravity:A_SVideoGravityResizeAspect];
}

- (instancetype)initWithURL:(NSURL *)URL videoGravity:(A_SVideoGravity)gravity;
{
  if (!(self = [super initWithLayerBlock:^CALayer *{
    AVPlayerLayer *layer = [[AVPlayerLayer alloc] init];
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:URL];
    
    layer.player = [[AVPlayer alloc] initWithPlayerItem:item];
    
    return layer;
  }])) { return nil; }
  
  self.gravity = gravity;
  
  return self;
}

- (void)setGravity:(A_SVideoGravity)gravity;
{
  switch (gravity) {
    case A_SVideoGravityResize:
      ((AVPlayerLayer *)self.layer).videoGravity = AVLayerVideoGravityResize;
      break;
    case A_SVideoGravityResizeAspect:
      ((AVPlayerLayer *)self.layer).videoGravity = AVLayerVideoGravityResizeAspect;
      break;
    case A_SVideoGravityResizeAspectFill:
      ((AVPlayerLayer *)self.layer).videoGravity = AVLayerVideoGravityResizeAspectFill;
      break;
    default:
      ((AVPlayerLayer *)self.layer).videoGravity = AVLayerVideoGravityResizeAspect;
      break;
  }
}

- (A_SVideoGravity)gravity;
{
  if ([((AVPlayerLayer *)self.layer).contentsGravity isEqualToString:AVLayerVideoGravityResize]) {
    return A_SVideoGravityResize;
  }
  if ([((AVPlayerLayer *)self.layer).contentsGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
    return A_SVideoGravityResizeAspectFill;
  }
  
  return A_SVideoGravityResizeAspect;
}

- (void)play;
{
  [[((AVPlayerLayer *)self.layer) player] play];
}

- (void)pause;
{
  [[((AVPlayerLayer *)self.layer) player] pause];
}

@end
