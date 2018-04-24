//
//  AnswersService.h
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AnswersService <NSObject>
- (NSArray *)parse:(NSDictionary *)data;
@end
