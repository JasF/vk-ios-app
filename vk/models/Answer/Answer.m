//
//  Answer.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Answer.h"

@implementation Answer

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"type", @"date"]];
    }];
}
    
- (BOOL)fillWithRepresentation:(NSDictionary *)representation users:(NSDictionary *)users {
    [EKMapper fillObject:self fromExternalRepresentation:representation withMapping:[Answer objectMapping]];
    NSDictionary *parent = representation[@"parent"];
    NSDictionary *feedback = representation[@"feedback"];
    NSArray *userIds = nil;
    if ([self.type isEqualToString:@"like_post"]) {
        self.post = [EKMapper objectFromExternalRepresentation:parent withMapping:[WallPost objectMapping]];
        userIds = [EKMapper arrayOfObjectsFromExternalRepresentation:feedback[@"items"] withMapping:[UserId objectMapping]];
    }
    else if ([self.type isEqualToString:@"like_photo"]) {
        self.photo = [EKMapper objectFromExternalRepresentation:parent withMapping:[Photo objectMapping]];
        userIds = [EKMapper arrayOfObjectsFromExternalRepresentation:feedback[@"items"] withMapping:[UserId objectMapping]];
    }
    else if ([self.type isEqualToString:@"comment_post"]) {
        self.post = [EKMapper objectFromExternalRepresentation:parent withMapping:[WallPost objectMapping]];
        self.feedbackComment = [EKMapper objectFromExternalRepresentation:feedback withMapping:[Comment objectMapping]];
        self.replyComment = [EKMapper objectFromExternalRepresentation:representation[@"reply"] withMapping:[Comment objectMapping]];
        userIds = @[[UserId userId:self.feedbackComment.from_id]];
    }
    else if ([self.type isEqualToString:@"reply_comment"]) {
        self.feedbackComment = [EKMapper objectFromExternalRepresentation:feedback withMapping:[Comment objectMapping]];
        self.parentComment = [EKMapper objectFromExternalRepresentation:parent withMapping:[Comment objectMapping]];
        userIds = @[[UserId userId:self.feedbackComment.from_id]];
    }
    else if ([self.type isEqualToString:@"like_comment"]) {
        self.parentComment = [EKMapper objectFromExternalRepresentation:parent withMapping:[Comment objectMapping]];
        userIds = [EKMapper arrayOfObjectsFromExternalRepresentation:feedback[@"items"] withMapping:[UserId objectMapping]];
    }
    else {
        NSCAssert(false, @"Unhandled answer type: %@", self.type);
        return NO;
    }
    
    NSMutableArray *usersArray = [NSMutableArray new];
    for (UserId *userId in userIds) {
        User *user = users[@(userId.user_id)];
        if (user) {
            [usersArray addObject:user];
        }
    }
    self.users = usersArray;
    return YES;
}
    
@end
