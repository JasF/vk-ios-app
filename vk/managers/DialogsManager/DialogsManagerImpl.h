//
//  DialogsManagerImpl.h
//  Electrum
//
//  Created by Jasf on 01.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "TextFieldDialog.h"
//#import "PasswordDialog.h"
#import "DialogsManager.h"
#import "HandlersFactory.h"
#import "RowsDialog.h"
//#import "WaitingDialog.h"
//#import "YesNoDialog.h"

@protocol PyDialogsManager <NSObject>
- (void)hello;
@end

@interface DialogsManagerImpl : NSObject <DialogsManager>
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
              textFieldDialog:(id<TextFieldDialog>)textFieldDialog
                   rowsDialog:(id<RowsDialog>)rowsDialog;
/*
             waitingDialog:(id<WaitingDialog>)waitingDialog
            passwordDialog:(id<PasswordDialog>)passwordDialog
               yesNoDialog:(id<YesNoDialog>)yesNoDialog;
 */
@end
