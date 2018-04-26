//
//  A_STextInput.m
//  Modified from YYText <https://github.com/ibireme/YYText>
//
//  Created by ibireme on 15/4/17.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Async_DisplayKit/A_STextInput.h>
#import <Async_DisplayKit/A_STextUtilities.h>


@implementation A_STextPosition

+ (instancetype)positionWithOffset:(NSInteger)offset {
  return [self positionWithOffset:offset affinity:A_STextAffinityForward];
}

+ (instancetype)positionWithOffset:(NSInteger)offset affinity:(A_STextAffinity)affinity {
  A_STextPosition *p = [self new];
  p->_offset = offset;
  p->_affinity = affinity;
  return p;
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [self.class positionWithOffset:_offset affinity:_affinity];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> (%@%@)", self.class, self, @(_offset), _affinity == A_STextAffinityForward ? @"F":@"B"];
}

- (NSUInteger)hash {
  return _offset * 2 + (_affinity == A_STextAffinityForward ? 1 : 0);
}

- (BOOL)isEqual:(A_STextPosition *)object {
  if (!object) return NO;
  return _offset == object.offset && _affinity == object.affinity;
}

- (NSComparisonResult)compare:(A_STextPosition *)otherPosition {
  if (!otherPosition) return NSOrderedAscending;
  if (_offset < otherPosition.offset) return NSOrderedAscending;
  if (_offset > otherPosition.offset) return NSOrderedDescending;
  if (_affinity == A_STextAffinityBackward && otherPosition.affinity == A_STextAffinityForward) return NSOrderedAscending;
  if (_affinity == A_STextAffinityForward && otherPosition.affinity == A_STextAffinityBackward) return NSOrderedDescending;
  return NSOrderedSame;
}

@end



@implementation A_STextRange {
  A_STextPosition *_start;
  A_STextPosition *_end;
}

- (instancetype)init {
  self = [super init];
  if (!self) return nil;
  _start = [A_STextPosition positionWithOffset:0];
  _end = [A_STextPosition positionWithOffset:0];
  return self;
}

- (A_STextPosition *)start {
  return _start;
}

- (A_STextPosition *)end {
  return _end;
}

- (BOOL)isEmpty {
  return _start.offset == _end.offset;
}

- (NSRange)asRange {
  return NSMakeRange(_start.offset, _end.offset - _start.offset);
}

+ (instancetype)rangeWithRange:(NSRange)range {
  return [self rangeWithRange:range affinity:A_STextAffinityForward];
}

+ (instancetype)rangeWithRange:(NSRange)range affinity:(A_STextAffinity)affinity {
  A_STextPosition *start = [A_STextPosition positionWithOffset:range.location affinity:affinity];
  A_STextPosition *end = [A_STextPosition positionWithOffset:range.location + range.length affinity:affinity];
  return [self rangeWithStart:start end:end];
}

+ (instancetype)rangeWithStart:(A_STextPosition *)start end:(A_STextPosition *)end {
  if (!start || !end) return nil;
  if ([start compare:end] == NSOrderedDescending) {
    A_STEXT_SWAP(start, end);
  }
  A_STextRange *range = [A_STextRange new];
  range->_start = start;
  range->_end = end;
  return range;
}

+ (instancetype)defaultRange {
  return [self new];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  return [self.class rangeWithStart:_start end:_end];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> (%@, %@)%@", self.class, self, @(_start.offset), @(_end.offset - _start.offset), _end.affinity == A_STextAffinityForward ? @"F":@"B"];
}

- (NSUInteger)hash {
  return (sizeof(NSUInteger) == 8 ? OSSwapInt64(_start.hash) : OSSwapInt32(_start.hash)) + _end.hash;
}

- (BOOL)isEqual:(A_STextRange *)object {
  if (!object) return NO;
  return [_start isEqual:object.start] && [_end isEqual:object.end];
}

@end



@implementation A_STextSelectionRect

@synthesize rect = _rect;
@synthesize writingDirection = _writingDirection;
@synthesize containsStart = _containsStart;
@synthesize containsEnd = _containsEnd;
@synthesize isVertical = _isVertical;

- (id)copyWithZone:(NSZone *)zone {
  A_STextSelectionRect *one = [self.class new];
  one.rect = _rect;
  one.writingDirection = _writingDirection;
  one.containsStart = _containsStart;
  one.containsEnd = _containsEnd;
  one.isVertical = _isVertical;
  return one;
}

@end
