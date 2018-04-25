//
//  MenuViewModel.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MenuViewModel <NSObject>
- (void)lentaTapped;
- (void)newsTapped;
- (void)dialogsTapped;
- (void)friendsTapped;
- (void)photosTapped;
- (void)answersTapped;
@end
