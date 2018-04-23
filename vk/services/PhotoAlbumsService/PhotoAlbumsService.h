//
//  PhotoAlbumsService.h
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PhotoAlbumsService <NSObject>
- (NSArray *)parse:(NSDictionary *)albums;
@end

