//
//  BaseViewController.h
//  Oxy Feed
//
//  Created by Jasf on 19.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

typedef NS_ENUM(NSInteger, ScreenType) {
    ScreenUnknown,
    ScreenWallPost,
    ScreenDetailPhoto,
    ScreenDetailVideo
};

@protocol BaseViewControllerDataSource <NSObject>
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset;
@end

@interface BaseViewController : ASViewController
@property (readonly) ScreenType screenType;
@end
