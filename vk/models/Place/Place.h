//
//  Place.h
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <EasyMapping/EasyMapping.h>

@interface Place : NSObject <EKMappingProtocol>
@property NSString *city;
@property NSString *country;
@property NSInteger created;
@property NSString *icon;
@property NSInteger id;
@property double latitude;
@property double longitude;
@property NSString *title;
@end
