//
//  ScreenNode.m
//  Sample
//
//  Created by Huy Nguyen on 16/09/15.
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

#import "ScreenNode.h"

@interface ScreenNode() <A_SMultiplexImageNodeDataSource, A_SMultiplexImageNodeDelegate, A_SImageDownloaderProtocol>
@end

@implementation ScreenNode

- (instancetype)init
{
  if (!(self = [super init])) {
    return nil;
  }

  // multiplex image node!
  // NB:  we're using a custom downloader with an artificial delay for this demo, but A_SPI_NRemoteImageDownloader works too!
  _imageNode = [[A_SMultiplexImageNode alloc] initWithCache:nil downloader:self];
  _imageNode.dataSource = self;
  _imageNode.delegate = self;
  
  // placeholder colour
  _imageNode.backgroundColor = A_SDisplayNodeDefaultPlaceholderColor();
  
  // load low-quality images before high-quality images
  _imageNode.downloadsIntermediateImages = YES;
  
  // simple status label.  Synchronous to avoid flicker / placeholder state when updating.
  _buttonNode = [[A_SButtonNode alloc] init];
  [_buttonNode addTarget:self action:@selector(reload) forControlEvents:A_SControlNodeEventTouchUpInside];
  _buttonNode.titleNode.displaysAsynchronously = NO;
  
  [self addSubnode:_imageNode];
  [self addSubnode:_buttonNode];
  
  return self;
}

- (void)start
{
  [self setText:@"loading…"];
  _buttonNode.userInteractionEnabled = NO;
  _imageNode.imageIdentifiers = @[ @"best", @"medium", @"worst" ]; // go!
}

- (void)reload
{
  [self start];
  [_imageNode reloadImageIdentifierSources];
}

- (void)setText:(NSString *)text
{
  NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0f]};
  NSAttributedString *string = [[NSAttributedString alloc] initWithString:text
                                                               attributes:attributes];
  [_buttonNode setAttributedTitle:string forState:UIControlStateNormal];
  [self setNeedsLayout];
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  A_SRatioLayoutSpec *imagePlaceholder = [A_SRatioLayoutSpec ratioLayoutSpecWithRatio:1 child:_imageNode];
  
  A_SStackLayoutSpec *verticalStack = [[A_SStackLayoutSpec alloc] init];
  verticalStack.direction = A_SStackLayoutDirectionVertical;
  verticalStack.spacing = 10;
  verticalStack.justifyContent = A_SStackLayoutJustifyContentCenter;
  verticalStack.alignItems = A_SStackLayoutAlignItemsCenter;
  verticalStack.children = @[imagePlaceholder, _buttonNode];
                                      
  return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(10, 10, 10, 10) child:verticalStack];
}

#pragma mark -
#pragma mark A_SMultiplexImageNode data source & delegate.

- (NSURL *)multiplexImageNode:(A_SMultiplexImageNode *)imageNode URLForImageIdentifier:(id)imageIdentifier
{
  if ([imageIdentifier isEqualToString:@"worst"]) {
    return [NSURL URLWithString:@"https://raw.githubusercontent.com/facebook/Async_DisplayKit/master/examples_extra/Multiplex/worst.png"];
  }
  
  if ([imageIdentifier isEqualToString:@"medium"]) {
    return [NSURL URLWithString:@"https://raw.githubusercontent.com/facebook/Async_DisplayKit/master/examples_extra/Multiplex/medium.png"];
  }
  
  if ([imageIdentifier isEqualToString:@"best"]) {
    return [NSURL URLWithString:@"https://raw.githubusercontent.com/facebook/Async_DisplayKit/master/examples_extra/Multiplex/best.png"];
  }
  
  // unexpected identifier
  return nil;
}

- (void)multiplexImageNode:(A_SMultiplexImageNode *)imageNode didFinishDownloadingImageWithIdentifier:(id)imageIdentifier error:(NSError *)error
{
  [self setText:[NSString stringWithFormat:@"loaded '%@'", imageIdentifier]];
  
  if ([imageIdentifier isEqualToString:@"best"]) {
    [self setText:[_buttonNode.titleNode.attributedText.string stringByAppendingString:@".  tap to reload"]];
    _buttonNode.userInteractionEnabled = YES;
  }
}


#pragma mark -
#pragma mark A_SImageDownloaderProtocol.

- (nullable id)downloadImageWithURL:(NSURL *)URL
                      callbackQueue:(dispatch_queue_t)callbackQueue
                   downloadProgress:(nullable A_SImageDownloaderProgress)downloadProgressBlock
                         completion:(A_SImageDownloaderCompletion)completion
{
  // if no callback queue is supplied, run on the main thread
  if (callbackQueue == nil) {
    callbackQueue = dispatch_get_main_queue();
  }
  
  // call completion blocks
  void (^handler)(NSURLResponse *, NSData *, NSError *) = ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
    // add an artificial delay
    usleep(1.0 * USEC_PER_SEC);
    
    // A_SMultiplexImageNode callbacks
    dispatch_async(callbackQueue, ^{
      if (downloadProgressBlock) {
        downloadProgressBlock(1.0f);
      }
      
      if (completion) {
        completion([UIImage imageWithData:data], connectionError, nil);
      }
    });
  };
  
  // let NSURLConnection do the heavy lifting
  NSURLRequest *request = [NSURLRequest requestWithURL:URL];
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:[[NSOperationQueue alloc] init]
                         completionHandler:handler];
  
  // return nil, don't support cancellation
  return nil;
}

- (void)cancelImageDownloadForIdentifier:(id)downloadIdentifier
{
  // no-op, don't support cancellation
}

@end
