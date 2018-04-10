//
//  Reposts.h
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@import EasyMapping;

@interface Reposts : NSObject <EKMappingProtocol>
@property NSInteger count;
@property NSInteger userReposted;
@end
