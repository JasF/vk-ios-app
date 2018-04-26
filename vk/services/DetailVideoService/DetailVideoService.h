//
//  DetailVideoService.h
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Video.h"

@protocol DetailVideoService <NSObject>
- (Video *)parseOne:(NSDictionary *)post;
- (NSArray *)parseComments:(NSDictionary *)comments;
@end
