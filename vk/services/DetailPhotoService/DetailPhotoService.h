//
//  DetailPhotoService.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Photo.h"

@protocol DetailPhotoService <NSObject>
- (Photo *)parseOne:(NSDictionary *)post;
- (NSArray *)parseComments:(NSDictionary *)comments;
@end
