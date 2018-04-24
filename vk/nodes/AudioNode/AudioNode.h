//
//  AudioNode.h
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "Audio.h"

@interface AudioNode : ASCellNode
- (id)initWithAudio:(Audio *)audio;
@end
