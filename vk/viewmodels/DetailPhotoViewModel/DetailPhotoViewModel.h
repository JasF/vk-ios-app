//
//  DetailPhotoViewModel.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Photo.h"

@protocol DetailPhotoViewModel <NSObject>
- (void)getPhotoWithCommentsOffset:(NSInteger)offset completion:(void(^)(Photo *photo, NSArray *comments))completion;
@end
