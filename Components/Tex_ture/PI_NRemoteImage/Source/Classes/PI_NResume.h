//
//  PI_NResume.h
//  PI_NRemoteImage
//
//  Created by Garrett Moon on 3/10/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PI_NResume : NSObject <NSCoding>

- (id)init NS_UNAVAILABLE;
+ (PI_NResume *)resumeData:(NSData *)resumeData ifRange:(NSString *)ifRange totalBytes:(long long)totalBytes;

@property (nonatomic, strong, readonly) NSData *resumeData;
@property (nonatomic, copy, readonly) NSString *ifRange;
@property (nonatomic, assign, readonly) long long totalBytes;

@end

NS_ASSUME_NONNULL_END
