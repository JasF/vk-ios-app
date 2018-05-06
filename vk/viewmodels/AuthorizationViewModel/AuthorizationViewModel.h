//
//  AuthorizationViewModel.h
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AuthorizationViewModel <NSObject>
@property (weak, nonatomic) UIViewController *viewController;
- (void)authorizeByApp;
- (void)authorizeByLogin;
- (BOOL)isAuthorizationOverAppAvailable;
@end
