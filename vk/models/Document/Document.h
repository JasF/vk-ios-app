//
//  Document.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SizedPhoto.h"

@import EasyMapping;

@interface Document : NSObject <EKMappingProtocol>
@property NSInteger id;
@property NSInteger owner_id;
@property NSString *title;
@property NSInteger size;
@property NSString *ext;
@property NSString *url;
@property NSInteger date;
@property NSInteger type;
@property NSArray<SizedPhoto *> *sizedPhotos;
- (NSString *)imageURL;
@end
