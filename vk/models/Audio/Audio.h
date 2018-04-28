//
//  Audio.h
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <EasyMapping/EasyMapping.h>

@interface Audio : NSObject <EKMappingProtocol>
@property NSInteger id;
@property NSInteger owner_id;
@property NSString *artist;
@property NSString *title;
@property NSInteger duration;
@property NSInteger date;
@property NSString *url;
@property NSInteger is_hq;
@property NSInteger content_restricted;
@end
