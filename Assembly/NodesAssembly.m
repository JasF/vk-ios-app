//
//  NodesAssembly.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "NodesAssembly.h"
#import "NodeFactoryImpl.h"
#import "WallPostNode.h"
#import "PostImagesNode.h"
#import "PostVideoNode.h"

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

- (ASDisplayNode *)postVideoNodeWithVideo:(Video *)video {
    return [TyphoonDefinition withClass:[PostVideoNode class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithVideo:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:video];
                 }];
            }];
}

@end
