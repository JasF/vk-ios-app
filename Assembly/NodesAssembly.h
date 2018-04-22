//
//  NodesAssembly.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TyphoonAssembly.h"
#import "NodeFactory.h"
#import "Dialog.h"
#import "Video.h"
#import "User.h"

@class WallPostNode;
@class ASDisplayNode;

@interface NodesAssembly : TyphoonAssembly
- (id<NodeFactory>)nodeFactory;
- (ASDisplayNode *)wallPostNodeWithData:(id)data embedded:(NSNumber *)embedded;
- (ASDisplayNode *)postImagesNodeWithAttachments:(NSArray *)attachments;
- (ASDisplayNode *)postVideoNodeWithVideo:(Video *)video;
- (ASDisplayNode *)dialogNode:(Dialog *)dialog;
- (ASDisplayNode *)userNode:(User *)user;
- (ASDisplayNode *)wallUserNode:(WallUser *)user;
@end
