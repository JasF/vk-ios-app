//
//  DialogsServiceImpl.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DialogsServiceImpl.h"
#import "User.h"

@interface DialogsServiceImpl ()
@property id<DialogsServiceHandlerProtocol> handler;
@end

@implementation DialogsServiceImpl

#pragma mark - Initialization
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory {
    NSCParameterAssert(handlersFactory);
    if (self = [self init]) {
        _handler = [handlersFactory dialogsServiceHandler];
    }
    return self;
}

#pragma mark - DialogsService
- (void)getDialogsWithOffset:(NSInteger)offset
                  completion:(void(^)(NSArray<Dialog *> *dialogs))completion {
    dispatch_python(^{
        NSDictionary *dialogsData = [self.handler getDialogs:@(offset)];
        [self processDialogsData:dialogsData
                      completion:completion];
    });
}

#pragma mark - Private Methods
- (void)processDialogsData:(NSDictionary *)dialogsData
                completion:(void(^)(NSArray *posts))completion {
    NSCAssert([dialogsData isKindOfClass:[NSDictionary class]] || !dialogsData, @"wallData unknown type");
    if (![dialogsData isKindOfClass:[NSDictionary class]]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil);
            }
        });
        return;
    }
    
    NSDictionary *response = dialogsData[@"response"];
    NSArray *users = dialogsData[@"users"];
    NSArray *items = response[@"items"];
    
    NSArray *dialogs = [EKMapper arrayOfObjectsFromExternalRepresentation:items
                                                              withMapping:[Dialog objectMapping]];
    
    NSArray *usersObjects = [EKMapper arrayOfObjectsFromExternalRepresentation:users
                                                                   withMapping:[User objectMapping]];
    
    NSMutableDictionary *usersDictionary = [NSMutableDictionary new];
    for (User *user in usersObjects) {
        [usersDictionary setObject:user forKey:@(user.identifier)];
    }
    
    for (Dialog *dialog in dialogs) {
        User *user = usersDictionary[@(ABS(dialog.message.user_id))];
        if (user) {
            dialog.username = [user nameString];
            dialog.avatarURLString = user.photo_100;
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) {
            completion(dialogs);
        }
    });
}

@end
