//
//  NodesAssembly.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "NodesAssembly.h"
#import "NodeFactoryImpl.h"
#import "WallPostNode.h"
#import "PostImagesNode.h"
#import "PostVideoNode.h"
#import "DialogNode.h"
#import "UserNode.h"
#import "CommentNode.h"
#import "PhotoAlbumNode.h"
#import "PhotoNode.h"
#import "AudioNode.h"
#import "FriendsNode.h"
#import "AnswerNode.h"
#import "VideoNode.h"
#import "DocumentNode.h"
#import "vk-Swift.h"

@implementation NodesAssembly

- (id<NodeFactory>)nodeFactory {
    return [TyphoonDefinition withClass:[NodeFactoryImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithNodesAssembly:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self];
                }];
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (ASDisplayNode *)wallPostNodeWithData:(id)data embedded:(NSNumber *)embedded {
    return [TyphoonDefinition withClass:[WallPostNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithPost:nodeFactory:embedded:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:data];
                     [initializer injectParameterWith:self.nodeFactory];
                     [initializer injectParameterWith:embedded];
                 }];
            }];
}

- (ASDisplayNode *)postImagesNodeWithAttachments:(NSArray *)attachments {
    return [TyphoonDefinition withClass:[PostImagesNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithAttachments:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:attachments];
                 }];
            }];
}

- (ASDisplayNode *)postImagesNodeWithPhotos:(NSArray *)photos {
    return [TyphoonDefinition withClass:[PostImagesNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithPhotos:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:photos];
                 }];
            }];
}

- (ASDisplayNode *)postVideoNodeWithVideo:(Video *)video {
    return [TyphoonDefinition withClass:[PostVideoNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithVideo:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:video];
                 }];
            }];
}

- (ASDisplayNode *)dialogNode:(Dialog *)dialog {
    return [TyphoonDefinition withClass:[DialogNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithDialog:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:dialog];
                 }];
            }];
}

- (ASDisplayNode *)userNode:(User *)user {
    return [TyphoonDefinition withClass:[UserNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithUser:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:user];
                 }];
            }];
}

- (ASDisplayNode *)commentNode:(Comment *)comment {
    return [TyphoonDefinition withClass:[CommentNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithComment:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:comment];
                 }];
            }];
}

- (ASDisplayNode *)photoAlbumNode:(PhotoAlbum *)photoAlbum {
    return [TyphoonDefinition withClass:[PhotoAlbumNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithPhotoAlbum:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:photoAlbum];
                 }];
            }];
}

- (ASDisplayNode *)photoNode:(Photo *)photo {
    return [TyphoonDefinition withClass:[PhotoNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithPhoto:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:photo];
                 }];
            }];
}

- (ASDisplayNode *)audioNode:(Audio *)audio {
    return [TyphoonDefinition withClass:[AudioNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithAudio:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:audio];
                 }];
            }];
}

- (ASDisplayNode *)friendsNode:(NSArray *)friends {
    return [TyphoonDefinition withClass:[FriendsNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithFriends:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:friends];
                 }];
            }];
}

- (ASDisplayNode *)answerNode:(NSArray *)friends {
    return [TyphoonDefinition withClass:[AnswerNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithAnswer:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:friends];
                 }];
            }];
}

- (ASDisplayNode *)videoNode:(Video *)video {
    return [TyphoonDefinition withClass:[VideoNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithVideo:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:video];
                 }];
            }];
}

- (ASDisplayNode *)documentNode:(Document *)document {
    return [TyphoonDefinition withClass:[DocumentNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithDocument:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:document];
                 }];
            }];
}

- (ASDisplayNode *)wallUserMessageNode:(User *)user {
    return [TyphoonDefinition withClass:[WallUserMessageNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(init:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:user];
                 }];
            }];
}

- (ASDisplayNode *)wallUserScrollNode:(User *)user {
    return [TyphoonDefinition withClass:[WallUserScrollNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(init:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:user];
                 }];
            }];
}

- (ASDisplayNode *)wallUserImageNode:(User *)user {
    return [TyphoonDefinition withClass:[WallUserImageNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(init:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:user];
                 }];
            }];
}

- (ASDisplayNode *)avatarNameDateNode:(User *)user date:(NSNumber *)date {
    return [TyphoonDefinition withClass:[AvatarNameDateNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(init:date:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:user];
                     [initializer injectParameterWith:date];
                 }];
            }];
}
@end
