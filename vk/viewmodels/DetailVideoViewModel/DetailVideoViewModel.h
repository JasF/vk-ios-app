//
//  DetailVideoViewModel.h
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Video.h"

@protocol DetailVideoViewModel <NSObject>
- (void)getVideoWithCommentsOffset:(NSInteger)offset completion:(void(^)(Video *video, NSArray *comments))completion;
@end
