//
//  MenuViewController.h
//  Horoscopes
//
//  Created by Jasf on 05.11.2017.
//  Copyright © 2017 Mail.Ru. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MenuScreenViewModel.h"

@interface MenuViewController : UIViewController
@property (strong, nonatomic) id<MenuScreenViewModel> viewModel;
@end
