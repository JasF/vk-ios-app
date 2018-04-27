//
//  ViewController.m
//  Tex_ture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /A_SDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ViewController.h"

#import <Async_DisplayKit/Async_DisplayKit.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  
  A_SNetworkImageNode *imageNode = [[A_SNetworkImageNode alloc] init];
  imageNode.URL = [NSURL URLWithString:@"https://i.pinimg.com/originals/07/44/38/074438e7c75034df2dcf37ba1057803e.gif"];
  // Uncomment to see animated webp support
  //  imageNode.URL = [NSURL URLWithString:@"https://storage.googleapis.com/downloads.webmproject.org/webp/images/dancing_banana2.lossless.webp"];
  imageNode.frame = self.view.bounds;
  imageNode.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  imageNode.contentMode = UIViewContentModeScaleAspectFit;
  
  [self.view addSubnode:imageNode];
}

@end