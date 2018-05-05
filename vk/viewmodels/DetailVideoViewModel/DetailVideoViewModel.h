//
//  DetailVideoViewModel.h
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Video.h"

@class Video;
@protocol DetailVideoViewModelDelegate <NSObject>
- (void)videoDidUpdated:(Video *)video;
@end

@protocol DetailVideoViewModel <NSObject>
@property (weak, nonatomic) id<DetailVideoViewModelDelegate> delegate;
- (void)getVideoWithCommentsOffset:(NSInteger)offset completion:(void(^)(Video *video, NSArray *comments))completion;
- (void)tappedOnVideo:(Video *)video;
@end
