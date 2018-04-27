//
//  RowsDialog.h
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

@protocol RowsDialog;

@protocol RowsDialogDelegate <NSObject>
- (void)rowsDialog:(id<RowsDialog>)dialog
     doneWithIndex:(NSInteger)index
         cancelled:(BOOL)cancelled;
@end

@protocol RowsDialog <NSObject>
@property (strong, nonatomic) id<RowsDialogDelegate> delegate;
- (void)showRowsDialogWithTitles:(NSArray *)titles;
@end
