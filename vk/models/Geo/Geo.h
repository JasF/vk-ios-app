//
//  Geo.h
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Place.h"

#import <EasyMapping/EasyMapping.h>

@interface Geo : NSObject <EKMappingProtocol>
@property NSString *coordinates;
@property Place *place;
@property NSString *type;
@end
