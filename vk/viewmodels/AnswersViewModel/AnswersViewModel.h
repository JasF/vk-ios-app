//
//  AnswersViewModel.h
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AnswersViewModel <NSObject>
- (void)getAnswers:(NSInteger)offset completion:(void(^)(NSArray *answers))completion;
- (void)menuTapped;
@end
