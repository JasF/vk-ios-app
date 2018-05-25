//
//  TextFieldDialog.h
//  Electrum
//
//  Created by Jasf on 25.03.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

@protocol TextFieldDialog;

@protocol TextFieldDialogDelegate <NSObject>
- (void)textFieldDialog:(id<TextFieldDialog>)dialog
           doneWithText:(NSString *)enteredText
                 cancel:(BOOL)cancel;
@end

@protocol TextFieldDialog <NSObject>
@property (strong, nonatomic) id<TextFieldDialogDelegate> delegate;
- (void)showTextFieldDialogWithMessage:(NSString *)message
                           placeholder:(NSString *)placeholder;
- (void)showTextFieldDialogWithMessage:(NSString *)message
                           placeholder:(NSString *)placeholder
                           onlyMessage:(BOOL)onlyMessage;

- (void)showWithMessage:(NSString *)message
         yesButtonTitle:(NSString *)yesButtonTitle
          noButtonTitle:(NSString *)noButtonTitle;

- (void)showDialogWithMessage:(NSString *)message
                           placeholder:(NSString *)placeholder
                           onlyMessage:(BOOL)onlyMessage;
@end
