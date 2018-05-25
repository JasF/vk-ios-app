//
//  DialogsManagerImpl.m
//  Electrum
//
//  Created by Jasf on 01.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DialogsManagerImpl.h"
#import "TextFieldDialog.h"
#import "RunLoop.h"

@protocol PyDialogsManagerDelegate <NSObject>
- (NSArray *)showTextFieldDialogWithText:(NSString *)text;
- (NSArray *)showRowsDialogWithTitles:(NSArray *)titles;
- (void)showDialogWithMessage:(NSString *)message;
- (NSArray *)showDialogWithMessage:(NSString *)message
                    yesButtonTitle:(NSString *)yesButtonTitle
                     noButtonTitle:(NSString *)noButtonTitle;
@end

@interface DialogsManagerImpl () <PyDialogsManagerDelegate, TextFieldDialogDelegate, RowsDialogDelegate>//, WaitingDialog, PasswordDialog, YesNoDialog>
@end

@implementation DialogsManagerImpl {
    id<PyDialogsManager> _handler;
    id<HandlersFactory> _handlersFactory;
    id<TextFieldDialog> _textFieldDialog;
    id<RowsDialog> _rowsDialog;
    /*
    id<WaitingDialog> _waitingDialog;
    id<PasswordDialog> _passwordDialog;
    id<YesNoDialog> _yesNoDialog;
     */
    NSString *_text;
    NSInteger _index;
    BOOL _cancel;
}

- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
              textFieldDialog:(id<TextFieldDialog>)textFieldDialog
                   rowsDialog:(id<RowsDialog>)rowsDialog
/*
             waitingDialog:(id<WaitingDialog>)waitingDialog
            passwordDialog:(id<PasswordDialog>)passwordDialog
               yesNoDialog:(id<YesNoDialog>)yesNoDialog
*/ {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(textFieldDialog);
    NSCParameterAssert(rowsDialog);
    /*
    NSCParameterAssert(waitingDialog);
    NSCParameterAssert(passwordDialog);
    NSCParameterAssert(yesNoDialog);
     */
    if (self = [self init]) {
        _handlersFactory = handlersFactory;
        _textFieldDialog = textFieldDialog;
        _textFieldDialog.delegate = self;
        _rowsDialog = rowsDialog;
        _rowsDialog.delegate = self;
        /*
        _waitingDialog = waitingDialog;
        _passwordDialog = passwordDialog;
        _yesNoDialog = yesNoDialog;
        [_pythonBridge setClassHandler:self name:@"TextFieldDialog"];
        [_pythonBridge setClassHandler:self name:@"WaitingDialog"];
        [_pythonBridge setClassHandler:self name:@"PasswordDialog"];
        [_pythonBridge setClassHandler:self name:@"YesNoDialog"];
         */
    }
    return self;
}

#pragma mark - DialogsManager
- (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _handler = [_handlersFactory dialogManagerHandlerWithDelegate:self];
    });
}

#pragma mark - WaitingDialog
- (void)showWaitingDialogWithMessage:(NSString *)message {
    //[_waitingDialog showWaitingDialogWithMessage:message];
}

- (void)waitingDialogClose {
    //[_waitingDialog waitingDialogClose];
}

#pragma mark - PasswordDialog
- (void)showPasswordDialogWithMessage:(NSString *)message {
    //[_passwordDialog showPasswordDialogWithMessage:message];
}

- (void)showYesNoDialogWithMessage:(NSString *)message {
    //[_yesNoDialog showYesNoDialogWithMessage:message];
}

#pragma mark - PyDialogsManagerDelegate
- (NSArray *)showTextFieldDialogWithText:(NSString *)text {
    [_textFieldDialog showTextFieldDialogWithMessage:text
                                         placeholder:@""];
    [[RunLoop shared] exec:(NSInteger)self];
    return @[_text.length ? _text : @"", @(_cancel)];
}

- (NSArray *)showRowsDialogWithTitles:(NSArray *)titles {
    [_rowsDialog showRowsDialogWithTitles:titles];
    [[RunLoop shared] exec:(NSInteger)self];
    return @[@(_index), @(_cancel)];
}

- (void)showDialogWithMessage:(NSString *)message {
    [_textFieldDialog showTextFieldDialogWithMessage:message
                                         placeholder:@""
                                         onlyMessage:YES];
}

- (NSArray *)showDialogWithMessage:(NSString *)message
                    yesButtonTitle:(NSString *)yesButtonTitle
                     noButtonTitle:(NSString *)noButtonTitle {
    [_textFieldDialog showWithMessage:message
                       yesButtonTitle:yesButtonTitle
                        noButtonTitle:noButtonTitle];
    [[RunLoop shared] exec:(NSInteger)self];
    return @[@(0), @(_cancel)];
}

#pragma mark - TextFieldDialogHandler
- (void)textFieldDialog:(id<TextFieldDialog>)dialog
           doneWithText:(NSString *)enteredText
                 cancel:(BOOL)cancel {
    _cancel = cancel;
    _text = enteredText;
    [[RunLoop shared] exit:(NSInteger)self];
}

#pragma mark - RowsDialogDelegate
- (void)rowsDialog:(id<RowsDialog>)dialog
     doneWithIndex:(NSInteger)index
         cancelled:(BOOL)cancelled {
    _index = index;
    _cancel = cancelled;
    [[RunLoop shared] exit:(NSInteger)self];
}
@end
