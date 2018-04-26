//
//  A_STextAttribute.m
//  Modified from YYText <https://github.com/ibireme/YYText>
//
//  Created by ibireme on 14/10/26.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "A_STextAttribute.h"
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import <Async_DisplayKit/NSAttributedString+A_SText.h>

NSString *const A_STextBackedStringAttributeName = @"A_STextBackedString";
NSString *const A_STextBindingAttributeName = @"A_STextBinding";
NSString *const A_STextShadowAttributeName = @"A_STextShadow";
NSString *const A_STextInnerShadowAttributeName = @"A_STextInnerShadow";
NSString *const A_STextUnderlineAttributeName = @"A_STextUnderline";
NSString *const A_STextStrikethroughAttributeName = @"A_STextStrikethrough";
NSString *const A_STextBorderAttributeName = @"A_STextBorder";
NSString *const A_STextBackgroundBorderAttributeName = @"A_STextBackgroundBorder";
NSString *const A_STextBlockBorderAttributeName = @"A_STextBlockBorder";
NSString *const A_STextAttachmentAttributeName = @"A_STextAttachment";
NSString *const A_STextHighlightAttributeName = @"A_STextHighlight";
NSString *const A_STextGlyphTransformAttributeName = @"A_STextGlyphTransform";

NSString *const A_STextAttachmentToken = @"\uFFFC";
NSString *const A_STextTruncationToken = @"\u2026";


A_STextAttributeType A_STextAttributeGetType(NSString *name){
  if (name.length == 0) return A_STextAttributeTypeNone;
  
  static NSMutableDictionary *dic;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    dic = [NSMutableDictionary new];
    NSNumber *All = @(A_STextAttributeTypeUIKit | A_STextAttributeTypeCoreText | A_STextAttributeTypeA_SText);
    NSNumber *CoreText_A_SText = @(A_STextAttributeTypeCoreText | A_STextAttributeTypeA_SText);
    NSNumber *UIKit_A_SText = @(A_STextAttributeTypeUIKit | A_STextAttributeTypeA_SText);
    NSNumber *UIKit_CoreText = @(A_STextAttributeTypeUIKit | A_STextAttributeTypeCoreText);
    NSNumber *UIKit = @(A_STextAttributeTypeUIKit);
    NSNumber *CoreText = @(A_STextAttributeTypeCoreText);
    NSNumber *A_SText = @(A_STextAttributeTypeA_SText);
    
    dic[NSFontAttributeName] = All;
    dic[NSKernAttributeName] = All;
    dic[NSForegroundColorAttributeName] = UIKit;
    dic[(id)kCTForegroundColorAttributeName] = CoreText;
    dic[(id)kCTForegroundColorFromContextAttributeName] = CoreText;
    dic[NSBackgroundColorAttributeName] = UIKit;
    dic[NSStrokeWidthAttributeName] = All;
    dic[NSStrokeColorAttributeName] = UIKit;
    dic[(id)kCTStrokeColorAttributeName] = CoreText_A_SText;
    dic[NSShadowAttributeName] = UIKit_A_SText;
    dic[NSStrikethroughStyleAttributeName] = UIKit;
    dic[NSUnderlineStyleAttributeName] = UIKit_CoreText;
    dic[(id)kCTUnderlineColorAttributeName] = CoreText;
    dic[NSLigatureAttributeName] = All;
    dic[(id)kCTSuperscriptAttributeName] = UIKit; //it's a CoreText attrubite, but only supported by UIKit...
    dic[NSVerticalGlyphFormAttributeName] = All;
    dic[(id)kCTGlyphInfoAttributeName] = CoreText_A_SText;
    dic[(id)kCTCharacterShapeAttributeName] = CoreText_A_SText;
    dic[(id)kCTRunDelegateAttributeName] = CoreText_A_SText;
    dic[(id)kCTBaselineClassAttributeName] = CoreText_A_SText;
    dic[(id)kCTBaselineInfoAttributeName] = CoreText_A_SText;
    dic[(id)kCTBaselineReferenceInfoAttributeName] = CoreText_A_SText;
    dic[(id)kCTWritingDirectionAttributeName] = CoreText_A_SText;
    dic[NSParagraphStyleAttributeName] = All;
    
    dic[NSStrikethroughColorAttributeName] = UIKit;
    dic[NSUnderlineColorAttributeName] = UIKit;
    dic[NSTextEffectAttributeName] = UIKit;
    dic[NSObliquenessAttributeName] = UIKit;
    dic[NSExpansionAttributeName] = UIKit;
    dic[(id)kCTLanguageAttributeName] = CoreText_A_SText;
    dic[NSBaselineOffsetAttributeName] = UIKit;
    dic[NSWritingDirectionAttributeName] = All;
    dic[NSAttachmentAttributeName] = UIKit;
    dic[NSLinkAttributeName] = UIKit;
    dic[(id)kCTRubyAnnotationAttributeName] = CoreText;
    
    dic[A_STextBackedStringAttributeName] = A_SText;
    dic[A_STextBindingAttributeName] = A_SText;
    dic[A_STextShadowAttributeName] = A_SText;
    dic[A_STextInnerShadowAttributeName] = A_SText;
    dic[A_STextUnderlineAttributeName] = A_SText;
    dic[A_STextStrikethroughAttributeName] = A_SText;
    dic[A_STextBorderAttributeName] = A_SText;
    dic[A_STextBackgroundBorderAttributeName] = A_SText;
    dic[A_STextBlockBorderAttributeName] = A_SText;
    dic[A_STextAttachmentAttributeName] = A_SText;
    dic[A_STextHighlightAttributeName] = A_SText;
    dic[A_STextGlyphTransformAttributeName] = A_SText;
  });
  NSNumber *num = dic[name];
  if (num) return num.integerValue;
  return A_STextAttributeTypeNone;
}


@implementation A_STextBackedString

+ (instancetype)stringWithString:(NSString *)string {
  A_STextBackedString *one = [self new];
  one.string = string;
  return one;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.string forKey:@"string"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  _string = [aDecoder decodeObjectForKey:@"string"];
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  one.string = self.string;
  return one;
}

@end


@implementation A_STextBinding

+ (instancetype)bindingWithDeleteConfirm:(BOOL)deleteConfirm {
  A_STextBinding *one = [self new];
  one.deleteConfirm = deleteConfirm;
  return one;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:@(self.deleteConfirm) forKey:@"deleteConfirm"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  _deleteConfirm = ((NSNumber *)[aDecoder decodeObjectForKey:@"deleteConfirm"]).boolValue;
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  one.deleteConfirm = self.deleteConfirm;
  return one;
}

@end


@implementation A_STextShadow

+ (instancetype)shadowWithColor:(UIColor *)color offset:(CGSize)offset radius:(CGFloat)radius {
  A_STextShadow *one = [self new];
  one.color = color;
  one.offset = offset;
  one.radius = radius;
  return one;
}

+ (instancetype)shadowWithNSShadow:(NSShadow *)nsShadow {
  if (!nsShadow) return nil;
  A_STextShadow *shadow = [self new];
  shadow.offset = nsShadow.shadowOffset;
  shadow.radius = nsShadow.shadowBlurRadius;
  id color = nsShadow.shadowColor;
  if (color) {
    if (CGColorGetTypeID() == CFGetTypeID((__bridge CFTypeRef)(color))) {
      color = [UIColor colorWithCGColor:(__bridge CGColorRef)(color)];
    }
    if ([color isKindOfClass:[UIColor class]]) {
      shadow.color = color;
    }
  }
  return shadow;
}

- (NSShadow *)nsShadow {
  NSShadow *shadow = [NSShadow new];
  shadow.shadowOffset = self.offset;
  shadow.shadowBlurRadius = self.radius;
  shadow.shadowColor = self.color;
  return shadow;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.color forKey:@"color"];
  [aCoder encodeObject:@(self.radius) forKey:@"radius"];
  [aCoder encodeObject:[NSValue valueWithCGSize:self.offset] forKey:@"offset"];
  [aCoder encodeObject:self.subShadow forKey:@"subShadow"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  _color = [aDecoder decodeObjectForKey:@"color"];
  _radius = ((NSNumber *)[aDecoder decodeObjectForKey:@"radius"]).floatValue;
  _offset = ((NSValue *)[aDecoder decodeObjectForKey:@"offset"]).CGSizeValue;
  _subShadow = [aDecoder decodeObjectForKey:@"subShadow"];
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  one.color = self.color;
  one.radius = self.radius;
  one.offset = self.offset;
  one.subShadow = self.subShadow.copy;
  return one;
}

@end


@implementation A_STextDecoration

- (instancetype)init {
  self = [super init];
  _style = A_STextLineStyleSingle;
  return self;
}

+ (instancetype)decorationWithStyle:(A_STextLineStyle)style {
  A_STextDecoration *one = [self new];
  one.style = style;
  return one;
}
+ (instancetype)decorationWithStyle:(A_STextLineStyle)style width:(NSNumber *)width color:(UIColor *)color {
  A_STextDecoration *one = [self new];
  one.style = style;
  one.width = width;
  one.color = color;
  return one;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:@(self.style) forKey:@"style"];
  [aCoder encodeObject:self.width forKey:@"width"];
  [aCoder encodeObject:self.color forKey:@"color"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  self.style = ((NSNumber *)[aDecoder decodeObjectForKey:@"style"]).unsignedIntegerValue;
  self.width = [aDecoder decodeObjectForKey:@"width"];
  self.color = [aDecoder decodeObjectForKey:@"color"];
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  one.style = self.style;
  one.width = self.width;
  one.color = self.color;
  return one;
}

@end


@implementation A_STextBorder

+ (instancetype)borderWithLineStyle:(A_STextLineStyle)lineStyle lineWidth:(CGFloat)width strokeColor:(UIColor *)color {
  A_STextBorder *one = [self new];
  one.lineStyle = lineStyle;
  one.strokeWidth = width;
  one.strokeColor = color;
  return one;
}

+ (instancetype)borderWithFillColor:(UIColor *)color cornerRadius:(CGFloat)cornerRadius {
  A_STextBorder *one = [self new];
  one.fillColor = color;
  one.cornerRadius = cornerRadius;
  one.insets = UIEdgeInsetsMake(-2, 0, 0, -2);
  return one;
}

- (instancetype)init {
  self = [super init];
  self.lineStyle = A_STextLineStyleSingle;
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:@(self.lineStyle) forKey:@"lineStyle"];
  [aCoder encodeObject:@(self.strokeWidth) forKey:@"strokeWidth"];
  [aCoder encodeObject:self.strokeColor forKey:@"strokeColor"];
  [aCoder encodeObject:@(self.lineJoin) forKey:@"lineJoin"];
  [aCoder encodeObject:[NSValue valueWithUIEdgeInsets:self.insets] forKey:@"insets"];
  [aCoder encodeObject:@(self.cornerRadius) forKey:@"cornerRadius"];
  [aCoder encodeObject:self.shadow forKey:@"shadow"];
  [aCoder encodeObject:self.fillColor forKey:@"fillColor"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  _lineStyle = ((NSNumber *)[aDecoder decodeObjectForKey:@"lineStyle"]).unsignedIntegerValue;
  _strokeWidth = ((NSNumber *)[aDecoder decodeObjectForKey:@"strokeWidth"]).doubleValue;
  _strokeColor = [aDecoder decodeObjectForKey:@"strokeColor"];
  _lineJoin = (CGLineJoin)((NSNumber *)[aDecoder decodeObjectForKey:@"join"]).unsignedIntegerValue;
  _insets = ((NSValue *)[aDecoder decodeObjectForKey:@"insets"]).UIEdgeInsetsValue;
  _cornerRadius = ((NSNumber *)[aDecoder decodeObjectForKey:@"cornerRadius"]).doubleValue;
  _shadow = [aDecoder decodeObjectForKey:@"shadow"];
  _fillColor = [aDecoder decodeObjectForKey:@"fillColor"];
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  one.lineStyle = self.lineStyle;
  one.strokeWidth = self.strokeWidth;
  one.strokeColor = self.strokeColor;
  one.lineJoin = self.lineJoin;
  one.insets = self.insets;
  one.cornerRadius = self.cornerRadius;
  one.shadow = self.shadow.copy;
  one.fillColor = self.fillColor;
  return one;
}

@end


@implementation A_STextAttachment

+ (instancetype)attachmentWithContent:(id)content {
  A_STextAttachment *one = [self new];
  one.content = content;
  return one;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.content forKey:@"content"];
  [aCoder encodeObject:[NSValue valueWithUIEdgeInsets:self.contentInsets] forKey:@"contentInsets"];
  [aCoder encodeObject:self.userInfo forKey:@"userInfo"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  _content = [aDecoder decodeObjectForKey:@"content"];
  _contentInsets = ((NSValue *)[aDecoder decodeObjectForKey:@"contentInsets"]).UIEdgeInsetsValue;
  _userInfo = [aDecoder decodeObjectForKey:@"userInfo"];
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  if ([self.content respondsToSelector:@selector(copy)]) {
    one.content = [self.content copy];
  } else {
    one.content = self.content;
  }
  one.contentInsets = self.contentInsets;
  one.userInfo = self.userInfo.copy;
  return one;
}

@end


@implementation A_STextHighlight

+ (instancetype)highlightWithAttributes:(NSDictionary *)attributes {
  A_STextHighlight *one = [self new];
  one.attributes = attributes;
  return one;
}

+ (instancetype)highlightWithBackgroundColor:(UIColor *)color {
  A_STextBorder *highlightBorder = [A_STextBorder new];
  highlightBorder.insets = UIEdgeInsetsMake(-2, -1, -2, -1);
  highlightBorder.cornerRadius = 3;
  highlightBorder.fillColor = color;
  
  A_STextHighlight *one = [self new];
  [one setBackgroundBorder:highlightBorder];
  return one;
}

- (void)setAttributes:(NSDictionary *)attributes {
  _attributes = attributes.mutableCopy;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  one.attributes = self.attributes.mutableCopy;
  return one;
}

- (void)_makeMutableAttributes {
  if (!_attributes) {
    _attributes = [NSMutableDictionary new];
  } else if (![_attributes isKindOfClass:[NSMutableDictionary class]]) {
    _attributes = _attributes.mutableCopy;
  }
}

- (void)setFont:(UIFont *)font {
  [self _makeMutableAttributes];
  if (font == (id)[NSNull null] || font == nil) {
    ((NSMutableDictionary *)_attributes)[(id)kCTFontAttributeName] = [NSNull null];
  } else {
    CTFontRef ctFont = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, NULL);
    if (ctFont) {
      ((NSMutableDictionary *)_attributes)[(id)kCTFontAttributeName] = (__bridge id)(ctFont);
      CFRelease(ctFont);
    }
  }
}

- (void)setColor:(UIColor *)color {
  [self _makeMutableAttributes];
  if (color == (id)[NSNull null] || color == nil) {
    ((NSMutableDictionary *)_attributes)[(id)kCTForegroundColorAttributeName] = [NSNull null];
    ((NSMutableDictionary *)_attributes)[NSForegroundColorAttributeName] = [NSNull null];
  } else {
    ((NSMutableDictionary *)_attributes)[(id)kCTForegroundColorAttributeName] = (__bridge id)(color.CGColor);
    ((NSMutableDictionary *)_attributes)[NSForegroundColorAttributeName] = color;
  }
}

- (void)setStrokeWidth:(NSNumber *)width {
  [self _makeMutableAttributes];
  if (width == (id)[NSNull null] || width == nil) {
    ((NSMutableDictionary *)_attributes)[(id)kCTStrokeWidthAttributeName] = [NSNull null];
  } else {
    ((NSMutableDictionary *)_attributes)[(id)kCTStrokeWidthAttributeName] = width;
  }
}

- (void)setStrokeColor:(UIColor *)color {
  [self _makeMutableAttributes];
  if (color == (id)[NSNull null] || color == nil) {
    ((NSMutableDictionary *)_attributes)[(id)kCTStrokeColorAttributeName] = [NSNull null];
    ((NSMutableDictionary *)_attributes)[NSStrokeColorAttributeName] = [NSNull null];
  } else {
    ((NSMutableDictionary *)_attributes)[(id)kCTStrokeColorAttributeName] = (__bridge id)(color.CGColor);
    ((NSMutableDictionary *)_attributes)[NSStrokeColorAttributeName] = color;
  }
}

- (void)setTextAttribute:(NSString *)attribute value:(id)value {
  [self _makeMutableAttributes];
  if (value == nil) value = [NSNull null];
  ((NSMutableDictionary *)_attributes)[attribute] = value;
}

- (void)setShadow:(A_STextShadow *)shadow {
  [self setTextAttribute:A_STextShadowAttributeName value:shadow];
}

- (void)setInnerShadow:(A_STextShadow *)shadow {
  [self setTextAttribute:A_STextInnerShadowAttributeName value:shadow];
}

- (void)setUnderline:(A_STextDecoration *)underline {
  [self setTextAttribute:A_STextUnderlineAttributeName value:underline];
}

- (void)setStrikethrough:(A_STextDecoration *)strikethrough {
  [self setTextAttribute:A_STextStrikethroughAttributeName value:strikethrough];
}

- (void)setBackgroundBorder:(A_STextBorder *)border {
  [self setTextAttribute:A_STextBackgroundBorderAttributeName value:border];
}

- (void)setBorder:(A_STextBorder *)border {
  [self setTextAttribute:A_STextBorderAttributeName value:border];
}

- (void)setAttachment:(A_STextAttachment *)attachment {
  [self setTextAttribute:A_STextAttachmentAttributeName value:attachment];
}

@end

