//
//  PI_NOperationGroupTests.m
//  PI_NOperationQueue
//
//  Created by Garrett Moon on 10/12/16.
//  Copyright © 2016 Pinterest. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <pthread.h>

#import <PI_NOperation/PI_NOperation.h>

static NSTimeInterval PI_NOperationGroupTestBlockTimeout = 20;

@interface PI_NOperationGroupTests : XCTestCase

@property PI_NOperationQueue *queue;

@end

@implementation PI_NOperationGroupTests

- (dispatch_time_t)timeout
{
  return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PI_NOperationGroupTestBlockTimeout * NSEC_PER_SEC));
}

- (void)setUp {
  [super setUp];
  self.queue = [[PI_NOperationQueue alloc] initWithMaxConcurrentOperations:5];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testAllOperationsRunBeforeCompletion
{
  __block NSUInteger operationsRun = 0;
  PI_NOperationGroup *group = [PI_NOperationGroup asyncOperationGroupWithQueue:self.queue];
  
  for (NSUInteger idx = 0; idx < 100; idx++) {
    __weak typeof(self) weakSelf = self;
    [group addOperation:^{
      typeof(self) strongSelf = weakSelf;
      @synchronized (strongSelf) {
        operationsRun++;
      }
    }];
  }
  
  XCTestExpectation *completionRun = [self expectationWithDescription:@"Completion Run"];
  
  __weak typeof(self) weakSelf = self;
  [group setCompletion:^{
    typeof(self) strongSelf = weakSelf;
    @synchronized (strongSelf) {
      XCTAssert(operationsRun == 100, @"Not all operations were run before completion");
    }
    [completionRun fulfill];
  }];
  
  [group start];
  
  [self waitForExpectationsWithTimeout:PI_NOperationGroupTestBlockTimeout handler:nil];
}

- (void)testWaitUntilOperationsComplete
{
  __block NSUInteger operationsRun = 0;
  PI_NOperationGroup *group = [PI_NOperationGroup asyncOperationGroupWithQueue:self.queue];
  
  for (NSUInteger idx = 0; idx < 100; idx++) {
    __weak typeof(self) weakSelf = self;
    [group addOperation:^{
      typeof(self) strongSelf = weakSelf;
      @synchronized (strongSelf) {
        operationsRun++;
      }
    }];
  }
  __block BOOL completionBlockCalled = NO;
  [group setCompletion:^{
    completionBlockCalled = YES;
  }];

  [group waitUntilComplete];
  XCTAssert(completionBlockCalled, @"Completion block should have been called after waiting.");
  
  @synchronized (self) {
    XCTAssert(operationsRun == 100, @"All operations should be run");
  }
}

- (void)testCancelation
{
  __block NSUInteger operationsRun = 0;
  PI_NOperationGroup *group = [PI_NOperationGroup asyncOperationGroupWithQueue:self.queue];
  
  const NSUInteger operationsToRun = 100;
  
  for (NSUInteger idx = 0; idx < operationsToRun; idx++) {
    __weak typeof(self) weakSelf = self;
    [group addOperation:^{
      usleep(10000);
      typeof(self) strongSelf = weakSelf;
      @synchronized (strongSelf) {
        operationsRun++;
      }
    }];
  }
  
  [group setCompletion:^{
    XCTAssert(NO, @"completion should not be run");
  }];
  
  [group start];
  [group cancel];
  
  usleep(10000 * operationsToRun);
  
  @synchronized (self) {
    XCTAssert(operationsRun < operationsToRun, @"All operations should not be run.");
  }
}

@end
