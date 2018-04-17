//
//  DialogScreenViewModelImpl.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DialogService.h"
#import "PythonBridge.h"
#import "DialogScreenViewModel.h"

@interface DialogScreenViewModelImpl : NSObject <DialogScreenViewModel>
- (instancetype)initWithDialogService:(id<DialogService>)dialogService
                               userId:(NSNumber *)userId
                         pythonBridge:(id<PythonBridge>)pythonBridge;
@end
