//
//  PythonBridge.h
//  Rubricon
//
//  Created by Jasf on 30.03.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import "PythonBridge.h"
#import "PythonBridgeExtension.h"

@protocol Modules;

@interface PythonBridgeImpl : NSObject <PythonBridge>
- (id)initWithExtension:(id<PythonBridgeExtension>)extension
                modules:(id<Modules>)modules;
@end
