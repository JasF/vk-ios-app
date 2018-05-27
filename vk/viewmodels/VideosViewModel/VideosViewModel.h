//
//  VideosViewModel.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Video.h"

@protocol VideosViewModel <NSObject>
- (void)getVideos:(NSInteger)offset completion:(void(^)(NSArray *videos, NSError *error))completion;
- (void)menuTapped;
- (void)tappedOnVideo:(Video *)video;
@end
