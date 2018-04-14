//
//  PI_NResume.m
//  PI_NRemoteImage
//
//  Created by Garrett Moon on 3/10/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PI_NResume.h"

@implementation PI_NResume

NSString * const kResumeDataKey = @"kResumeDataKey";
NSString * const kIfRangeKey = @"kIfRangeKey";
NSString * const kTotalBytesKey = @"kTotalBytesKey";

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        _resumeData = [aDecoder decodeObjectForKey:kResumeDataKey];
        _ifRange = [aDecoder decodeObjectForKey:kIfRangeKey];
        _totalBytes = [aDecoder decodeInt64ForKey:kTotalBytesKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_resumeData forKey:kResumeDataKey];
    [aCoder encodeObject:_ifRange forKey:kIfRangeKey];
    [aCoder encodeInt64:_totalBytes forKey:kTotalBytesKey];
}

+ (PI_NResume *)resumeData:(NSData *)resumeData ifRange:(NSString *)ifRange totalBytes:(long long)totalBytes
{
    PI_NResume *resume = [[PI_NResume alloc] initWithResumeData:resumeData ifRange:ifRange totalBytes:totalBytes];
    return resume;
}

- (PI_NResume *)initWithResumeData:(NSData *)resumeData ifRange:(NSString *)ifRange totalBytes:(long long)totalBytes
{
    if (self = [super init]) {
        NSAssert(resumeData.length > 0 && ifRange.length > 0 && totalBytes > 0, @"PI_NResume must have all fields non-nil and non-zero length.");
        _resumeData = resumeData;
        _ifRange = ifRange;
        _totalBytes = totalBytes;
    }
    return self;
}

@end
