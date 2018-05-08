//
//  Counters.h
//  vk
//
//  Created by Jasf on 08.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EasyMapping/EasyMapping.h>

@interface Counters : NSObject <EKMappingProtocol>
@property NSInteger photos;
@property NSInteger albums;
@property NSInteger topics;
@property NSInteger videos;
@property NSInteger audios;
@end
