//
//  Cover.h
//  vk
//
//  Created by Jasf on 08.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EasyMapping/EasyMapping.h>

@interface Cover : NSObject <EKMappingProtocol>
@property NSInteger width;
@property NSInteger height;
@property NSString *url;
@end
