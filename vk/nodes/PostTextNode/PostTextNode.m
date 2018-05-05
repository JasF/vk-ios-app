//
//  PostTextNode.m
//  vk
//
//  Created by Jasf on 05.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostTextNode.h"
#import "TextStyles.h"

NSString *kLinkAttributeName = @"TextLinkAttributeName";

@interface PostTextNode () <ASTextNodeDelegate>
@end

@implementation PostTextNode
- (id)init {
    if (self = [super init]) {
        self.linkAttributeNames = @[kLinkAttributeName];
        self.maximumNumberOfLines = 12;
        self.truncationMode = NSLineBreakByTruncatingTail;
        self.truncationAttributedText = [[NSAttributedString alloc] initWithString:@"\n"];
        self.additionalTruncationMessage = [[NSAttributedString alloc] initWithString:L(@"show_fully")
                                                                                attributes:[TextStyles truncationStyle]];
        self.delegate = self;
        self.userInteractionEnabled = YES;
        self.passthroughNonlinkTouches = YES;   // passes touches through when they aren't on a link
    }
    return self;
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    NSMutableAttributedString *mutableString = [attributedText mutableCopy];
    NSDataDetector *urlDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    [urlDetector enumerateMatchesInString:mutableString.string options:kNilOptions range:NSMakeRange(0, mutableString.string.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
        if (result.resultType == NSTextCheckingTypeLink) {
            NSMutableDictionary *linkAttributes = [[NSMutableDictionary alloc] initWithDictionary:[TextStyles postLinkStyle]];
            linkAttributes[kLinkAttributeName] = [NSURL URLWithString:result.URL.absoluteString];
            [mutableString addAttributes:linkAttributes range:result.range];
        }
        
    }];
    
    [super setAttributedText:mutableString];
}


#pragma mark - <ASTextNodeDelegate>

- (BOOL)textNode:(ASTextNode *)richTextNode shouldHighlightLinkAttribute:(NSString *)attribute value:(id)value atPoint:(CGPoint)point
{
    // Opt into link highlighting -- tap and hold the link to try it!  must enable highlighting on a layer, see -didLoad
    return YES;
}

- (void)textNode:(ASTextNode *)richTextNode tappedLinkAttribute:(NSString *)attribute value:(NSURL *)URL atPoint:(CGPoint)point textRange:(NSRange)textRange
{
    // The node tapped a link, open it
    [[UIApplication sharedApplication] openURL:URL];
}

- (void)textNodeTappedTruncationToken:(ASTextNode *)textNode {
    self.maximumNumberOfLines = 0.f;
    [self setNeedsLayout];
}
@end
