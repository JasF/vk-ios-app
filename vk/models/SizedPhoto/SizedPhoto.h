//
//  SizedPhoto.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <EasyMapping/EasyMapping.h>

@interface SizedPhoto : NSObject <EKMappingProtocol>
@property NSString *src;
@property NSInteger width;
@property NSInteger height;
@property NSString *type;
+ (SizedPhoto *)getWithType:(NSString *)type array:(NSArray *)array;
@end
