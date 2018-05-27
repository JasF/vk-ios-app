//
//  PhotoAlbumsViewModel.h
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol PhotoAlbumsViewModel <NSObject>
- (void)getPhotoAlbums:(NSInteger)offset completion:(void(^)(NSArray *albums, NSError *error))completion;
- (void)clickedOnAlbumWithId:(NSInteger)albumId;
- (void)menuTapped;
@end
