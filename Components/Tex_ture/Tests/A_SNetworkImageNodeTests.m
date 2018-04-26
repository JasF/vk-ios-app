//
//  A_SNetworkImageNodeTests.m
//  Tex_ture
//
//  Created by Adlai Holler on 10/14/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <Async_DisplayKit/Async_DisplayKit.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>

@interface A_SNetworkImageNodeTests : XCTestCase

@end

@interface A_STestImageDownloader : NSObject <A_SImageDownloaderProtocol>
@end
@interface A_STestImageCache : NSObject <A_SImageCacheProtocol>
@end

@implementation A_SNetworkImageNodeTests {
  A_SNetworkImageNode *node;
  id downloader;
  id cache;
}

- (void)setUp
{
  [super setUp];
  cache = [OCMockObject partialMockForObject:[[A_STestImageCache alloc] init]];
  downloader = [OCMockObject partialMockForObject:[[A_STestImageDownloader alloc] init]];
  node = [[A_SNetworkImageNode alloc] initWithCache:cache downloader:downloader];
}

/// Test is flaky: https://github.com/facebook/Async_DisplayKit/issues/2898
- (void)DISABLED_testThatProgressBlockIsSetAndClearedCorrectlyOnVisibility
{
  node.URL = [NSURL URLWithString:@"http://imageA"];

  // Enter preload range, wait for download start.
  [[[downloader expect] andForwardToRealObject] downloadImageWithURL:[OCMArg isNotNil] callbackQueue:OCMOCK_ANY downloadProgress:OCMOCK_ANY completion:OCMOCK_ANY];
  [node enterInterfaceState:A_SInterfaceStatePreload];
  [downloader verifyWithDelay:5];

  // Make the node visible.
  [[downloader expect] setProgressImageBlock:[OCMArg isNotNil] callbackQueue:OCMOCK_ANY withDownloadIdentifier:@0];
  [node enterInterfaceState:A_SInterfaceStateInHierarchy];
  [downloader verify];

  // Make the node invisible.
  [[downloader expect] setProgressImageBlock:[OCMArg isNil] callbackQueue:OCMOCK_ANY withDownloadIdentifier:@0];
  [node exitInterfaceState:A_SInterfaceStateInHierarchy];
  [downloader verify];
}

- (void)testThatProgressBlockIsSetAndClearedCorrectlyOnChangeURL
{
  [node enterInterfaceState:A_SInterfaceStateInHierarchy];

  // Set URL while visible, should set progress block
  [[downloader expect] setProgressImageBlock:[OCMArg isNotNil] callbackQueue:OCMOCK_ANY withDownloadIdentifier:@0];
  node.URL = [NSURL URLWithString:@"http://imageA"];
  [downloader verifyWithDelay:5];

  // Change URL while visible, should clear prior block and set new one
  [[downloader expect] setProgressImageBlock:[OCMArg isNil] callbackQueue:OCMOCK_ANY withDownloadIdentifier:@0];
  [[downloader expect] cancelImageDownloadForIdentifier:@0];
  [[downloader expect] setProgressImageBlock:[OCMArg isNotNil] callbackQueue:OCMOCK_ANY withDownloadIdentifier:@1];
  node.URL = [NSURL URLWithString:@"http://imageB"];
  [downloader verifyWithDelay:5];
}

- (void)testThatSettingAnImageWillStayForEnteringAndExitingPreloadState
{
  UIImage *image = [[UIImage alloc] init];
  A_SNetworkImageNode *networkImageNode = [[A_SNetworkImageNode alloc] init];
  networkImageNode.image = image;
  [networkImageNode enterInterfaceState:A_SInterfaceStatePreload];
  XCTAssertEqualObjects(image, networkImageNode.image);
  [networkImageNode exitInterfaceState:A_SInterfaceStatePreload];
  XCTAssertEqualObjects(image, networkImageNode.image);
}

@end

@implementation A_STestImageCache

- (void)cachedImageWithURL:(NSURL *)URL callbackQueue:(dispatch_queue_t)callbackQueue completion:(A_SImageCacherCompletion)completion
{
  A_SDisplayNodeAssert(callbackQueue == dispatch_get_main_queue(), @"A_STestImageCache expects main queue for callback.");
  completion(nil);
}

@end

@implementation A_STestImageDownloader {
  NSInteger _currentDownloadID;
}

- (void)cancelImageDownloadForIdentifier:(id)downloadIdentifier
{
  // nop
}

- (id)downloadImageWithURL:(NSURL *)URL callbackQueue:(dispatch_queue_t)callbackQueue downloadProgress:(A_SImageDownloaderProgress)downloadProgress completion:(A_SImageDownloaderCompletion)completion
{
  return @(_currentDownloadID++);
}

- (void)setProgressImageBlock:(A_SImageDownloaderProgressImage)progressBlock callbackQueue:(dispatch_queue_t)callbackQueue withDownloadIdentifier:(id)downloadIdentifier
{
  // nop
}
@end
