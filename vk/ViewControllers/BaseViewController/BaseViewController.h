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

@protocol NodeFactory;

@protocol BaseViewControllerDataSource <NSObject>
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset;
@end

@interface BaseViewController : ASViewController
@property id<NodeFactory> nodeFactory;
@property (readonly) ScreenType screenType;
- (void)showNoConnectionAlert;
@end
