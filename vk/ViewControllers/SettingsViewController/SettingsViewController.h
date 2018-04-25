//
//  SettingsViewController.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseCollectionViewController.h"
#import "SettingsViewModel.h"

@interface SettingsViewController : BaseCollectionViewController
- (instancetype)initWithViewModel:(id<SettingsViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
