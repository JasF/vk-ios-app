//
//  A_SPerformanceTestContext.h
//  Tex_ture
//
//  Created by Adlai Holler on 8/28/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTestAssertionsImpl.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

#define A_SXCTAssertRelativePerformanceInRange(test, caseName, min, max) \
  _XCTPrimitiveAssertLessThanOrEqual(self, test.results[caseName].relativePerformance, @#caseName, max, @#max);\
  _XCTPrimitiveAssertGreaterThanOrEqual(self, test.results[caseName].relativePerformance, @#caseName, min, @#min)

NS_ASSUME_NONNULL_BEGIN

typedef void (^A_STestPerformanceCaseBlock)(NSUInteger i, dispatch_block_t startMeasuring, dispatch_block_t stopMeasuring);

@interface A_SPerformanceTestResult : NSObject
@property (nonatomic, readonly) NSTimeInterval timePer1000;
@property (nonatomic, readonly) NSString *caseName;

@property (nonatomic, readonly, getter=isReferenceCase) BOOL referenceCase;
@property (nonatomic, readonly) float relativePerformance;

@property (nonatomic, readonly) NSMutableDictionary *userInfo;
@end

@interface A_SPerformanceTestContext : NSObject

/**
 * The first case you add here will be considered the reference case.
 */
- (void)addCaseWithName:(NSString *)caseName block:(A_S_NOESCAPE A_STestPerformanceCaseBlock)block;

@property (nonatomic, copy, readonly) NSDictionary<NSString *, A_SPerformanceTestResult *> *results;

- (BOOL)areAllUserInfosEqual;

@end

NS_ASSUME_NONNULL_END
