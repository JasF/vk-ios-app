//
//  NodeFactoryImpl.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "NodeFactoryImpl.h"
#import "NodesAssembly.h"
#import "WallPost.h"
#import "Dialog.h"
#import "Comment.h"
#import "PhotoAlbum.h"
#import "Answer.h"
#import "Video.h"
#import "Document.h"
#import "vk-Swift.h"

@implementation NodeFactoryImpl {
    NodesAssembly *_assembly;
}

#pragma mark - Initialization
- (instancetype)initWithNodesAssembly:(NodesAssembly *)nodesAssembly {
    NSCParameterAssert(nodesAssembly);
    if (self = [super init]) {
        _assembly = nodesAssembly;
    }
    return self;
}

- (ASDisplayNode *)nodeForItem:(id)item {
    return [self nodeForItem:item embedded:NO];
}

- (ASDisplayNode *)nodeForItem:(id)item embedded:(BOOL)embedded {
    if ([item isKindOfClass:[WallPost class]]) {
        return [_assembly wallPostNodeWithData:item embedded:@(embedded)];
    }
    else if ([item isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)item;
        if ([array.firstObject isKindOfClass:[Photo class]]) {
            return [_assembly postImagesNodeWithPhotos:array];
        }
        else if ([array.firstObject isKindOfClass:[Attachments class]]) {
            Attachments *attachment = (Attachments *)array.firstObject;
            if (attachment.type == AttachmentPhoto) {
                return [_assembly postImagesNodeWithAttachments:array];
            }
            else {
                NSCAssert(false, @"Unknown attachment type: %@", @(attachment.type));
            }
        }
        else {
            NSCAssert(false, @"Unknown object type: %@", array.firstObject);
        }
    }
    else if ([item isKindOfClass:[Attachments class]]) {
        Attachments *attachment = (Attachments *)item;
        if (attachment.type == AttachmentVideo) {
            return [_assembly postVideoNodeWithVideo:attachment.video];
        }
        else {
            return nil;
            NSCAssert(false, @"Unknown attachment type: %@", @(attachment.type));
        }
    }
    else if ([item isKindOfClass:[Dialog class]]) {
        return [_assembly dialogNode:item];
    }
    else if ([item isKindOfClass:[User class]]) {
        return [_assembly userNode:item];
    }
    else if ([item isKindOfClass:[Comment class]]) {
        return [_assembly commentNode:item];
    }
    else if ([item isKindOfClass:[PhotoAlbum class]]) {
        return [_assembly photoAlbumNode:item];
    }
    else if ([item isKindOfClass:[Photo class]]) {
        return [_assembly photoNode:item];
    }
    else if ([item isKindOfClass:[Audio class]]) {
        return [_assembly audioNode:item];
    }
    else if ([item isKindOfClass:[Answer class]]) {
        return [_assembly answerNode:item];
    }
    else if ([item isKindOfClass:[Video class]]) {
        return [_assembly videoNode:item];
    }
    else if ([item isKindOfClass:[Document class]]) {
        return [_assembly documentNode:item];
    }
    else if ([item isKindOfClass:[WallUserCellModel class]]) {
        WallUserCellModel *model = (WallUserCellModel *)item;
        if (model.type == WallUserCellModelTypeMessage) {
            return [_assembly wallUserMessageNode:model.user];
        }
        else if (model.type == WallUserCellModelTypeActions) {
            return [_assembly wallUserScrollNode:model.user];
        }
        else if (model.type == WallUserCellModelTypeImage) {
            return [_assembly wallUserImageNode:model.user];
        }
        else if (model.type == WallUserCellModelTypeAvatarNameDate) {
            return [_assembly avatarNameDateNode:model.user date:@(model.date)];
        }
    }
    NSCAssert(false, @"Undeterminated item class: %@", item);
    return nil;
}

- (ASDisplayNode *)friendsNodeWithArray:(NSArray *)array {
    return [_assembly friendsNode:array];
}

@end
