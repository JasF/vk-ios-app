//
//  DialogService.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import "Message.h"

@protocol DialogService <NSObject>
- (NSArray<Message *> *)parse:(NSDictionary *)messagesData;
- (Message *)parseOne:(NSDictionary *)messageDictionary;
- (User *)parseUser:(NSDictionary *)userDictionary;
@end

