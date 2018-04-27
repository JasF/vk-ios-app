//
//  NodesAssembly.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ServicesAssembly.h"
#import "TyphoonAssembly.h"
#import "NodeFactory.h"
#import "Dialog.h"
#import "Video.h"
#import "User.h"
#import "Comment.h"
#import "PhotoAlbum.h"
#import "Photo.h"
#import "Audio.h"
#import "Answer.h"
#import "Video.h"
#import "Document.h"

@class WallPostNode;
@class ASDisplayNode;

@interface NodesAssembly : TyphoonAssembly
@property ServicesAssembly *servicesAssembly;
- (id<NodeFactory>)nodeFactory;
- (ASDisplayNode *)wallPostNodeWithData:(id)data embedded:(NSNumber *)embedded;
- (ASDisplayNode *)postImagesNodeWithAttachments:(NSArray *)attachments;
- (ASDisplayNode *)postImagesNodeWithPhotos:(NSArray *)photos;
- (ASDisplayNode *)postVideoNodeWithVideo:(Video *)video;
- (ASDisplayNode *)dialogNode:(Dialog *)dialog;
- (ASDisplayNode *)userNode:(User *)user;
- (ASDisplayNode *)wallUserNode:(WallUser *)user;
- (ASDisplayNode *)commentNode:(Comment *)comment;
- (ASDisplayNode *)photoAlbumNode:(PhotoAlbum *)photoAlbum;
- (ASDisplayNode *)photoNode:(Photo *)photo;
- (ASDisplayNode *)audioNode:(Audio *)audio;
- (ASDisplayNode *)friendsNode:(NSArray *)friends;
- (ASDisplayNode *)answerNode:(Answer *)answer;
- (ASDisplayNode *)videoNode:(Video *)video;
- (ASDisplayNode *)documentNode:(Document *)document;
@end
