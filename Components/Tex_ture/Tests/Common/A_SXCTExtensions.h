/**
 * XCTest extensions for CGGeometry.
 *
 * Prefer these to XCTAssert(CGRectEqualToRect(...)) because you get output
 * that tells you what went wrong.
 * Could use NSValue, but using strings makes the description messages shorter.
 */

#import <XCTest/XCTestAssertionsImpl.h>

#define A_SXCTAssertEqualSizes(s0, s1, ...) \
  _XCTPrimitiveAssertEqualObjects(self, NSStringFromCGSize(s0), @#s0, NSStringFromCGSize(s1), @#s1, __VA_ARGS__)

#define A_SXCTAssertNotEqualSizes(s0, s1, ...) \
  _XCTPrimitiveAssertNotEqualObjects(self, NSStringFromCGSize(s0), @#s0, NSStringFromCGSize(s1), @#s1, __VA_ARGS__)

#define A_SXCTAssertEqualPoints(p0, p1, ...) \
  _XCTPrimitiveAssertEqualObjects(self, NSStringFromCGPoint(p0), @#p0, NSStringFromCGPoint(p1), @#p1, __VA_ARGS__)

#define A_SXCTAssertNotEqualPoints(p0, p1, ...) \
  _XCTPrimitiveAssertNotEqualObjects(self, NSStringFromCGPoint(p0), @#p0, NSStringFromCGPoint(p1), @#p1, __VA_ARGS__)

#define A_SXCTAssertEqualRects(r0, r1, ...) \
  _XCTPrimitiveAssertEqualObjects(self, NSStringFromCGRect(r0), @#r0, NSStringFromCGRect(r1), @#r1, __VA_ARGS__)

#define A_SXCTAssertNotEqualRects(r0, r1, ...) \
  _XCTPrimitiveAssertNotEqualObjects(self, NSStringFromCGRect(r0), @#r0, NSStringFromCGRect(r1), @#r1, __VA_ARGS__)

#define A_SXCTAssertEqualDimensions(r0, r1, ...) \
  _XCTPrimitiveAssertEqualObjects(self, NSStringFromA_SDimension(r0), @#r0, NSStringFromA_SDimension(r1), @#r1, __VA_ARGS__)

#define A_SXCTAssertNotEqualDimensions(r0, r1, ...) \
  _XCTPrimitiveAssertNotEqualObjects(self, NSStringFromA_SDimension(r0), @#r0, NSStringFromA_SDimension(r1), @#r1, __VA_ARGS__)

#define A_SXCTAssertEqualSizeRanges(r0, r1, ...) \
  _XCTPrimitiveAssertEqualObjects(self, NSStringFromA_SSizeRange(r0), @#r0, NSStringFromA_SSizeRange(r1), @#r1, __VA_ARGS__)
