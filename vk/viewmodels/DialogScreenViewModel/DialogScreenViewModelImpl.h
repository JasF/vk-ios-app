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
#import "HandlersFactory.h"
#import "DialogScreenViewModel.h"

@protocol PyDialogScreenViewModel <NSObject>
- (NSDictionary *)getMessages:(NSNumber *)offset
                       userId:(NSNumber *)userId;

- (NSDictionary *)getMessages:(NSNumber *)offset
                       userId:(NSNumber *)userId
               startMessageId:(NSNumber *)startMessageId;

- (NSNumber *)sendTextMessage:(NSString *)text userId:(NSNumber *)userId;
@end

@interface DialogScreenViewModelImpl : NSObject <DialogScreenViewModel>
- (instancetype)initWithDialogService:(id<DialogService>)dialogService
                      handlersFactory:(id<HandlersFactory>)handlersFactory
                               userId:(NSNumber *)userId
                         pythonBridge:(id<PythonBridge>)pythonBridge;
@end
