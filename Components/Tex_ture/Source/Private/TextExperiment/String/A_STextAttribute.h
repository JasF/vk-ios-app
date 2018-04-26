//
//  A_STextAttribute.h
//  Modified from YYText <https://github.com/ibireme/YYText>
//
//  Created by ibireme on 14/10/26.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Enum Define

/// The attribute type
typedef NS_OPTIONS(NSInteger, A_STextAttributeType) {
  A_STextAttributeTypeNone     = 0,
  A_STextAttributeTypeUIKit    = 1 << 0, ///< UIKit attributes, such as UILabel/UITextField/drawInRect.
  A_STextAttributeTypeCoreText = 1 << 1, ///< CoreText attributes, used by CoreText.
  A_STextAttributeTypeA_SText   = 1 << 2, ///< A_SText attributes, used by A_SText.
};

/// Get the attribute type from an attribute name.
extern A_STextAttributeType A_STextAttributeGetType(NSString *attributeName);

/**
 Line style in A_SText (similar to NSUnderlineStyle).
 */
typedef NS_OPTIONS (NSInteger, A_STextLineStyle) {
  // basic style (bitmask:0xFF)
  A_STextLineStyleNone       = 0x00, ///< (        ) Do not draw a line (Default).
  A_STextLineStyleSingle     = 0x01, ///< (──────) Draw a single line.
  A_STextLineStyleThick      = 0x02, ///< (━━━━━━━) Draw a thick line.
  A_STextLineStyleDouble     = 0x09, ///< (══════) Draw a double line.
  
  // style pattern (bitmask:0xF00)
  A_STextLineStylePatternSolid      = 0x000, ///< (────────) Draw a solid line (Default).
  A_STextLineStylePatternDot        = 0x100, ///< (‑ ‑ ‑ ‑ ‑ ‑) Draw a line of dots.
  A_STextLineStylePatternDash       = 0x200, ///< (— — — —) Draw a line of dashes.
  A_STextLineStylePatternDashDot    = 0x300, ///< (— ‑ — ‑ — ‑) Draw a line of alternating dashes and dots.
  A_STextLineStylePatternDashDotDot = 0x400, ///< (— ‑ ‑ — ‑ ‑) Draw a line of alternating dashes and two dots.
  A_STextLineStylePatternCircleDot  = 0x900, ///< (••••••••••••) Draw a line of small circle dots.
};

/**
 Text vertical alignment.
 */
typedef NS_ENUM(NSInteger, A_STextVerticalAlignment) {
  A_STextVerticalAlignmentTop =    0, ///< Top alignment.
  A_STextVerticalAlignmentCenter = 1, ///< Center alignment.
  A_STextVerticalAlignmentBottom = 2, ///< Bottom alignment.
};

/**
 The direction define in A_SText.
 */
typedef NS_OPTIONS(NSUInteger, A_STextDirection) {
  A_STextDirectionNone   = 0,
  A_STextDirectionTop    = 1 << 0,
  A_STextDirectionRight  = 1 << 1,
  A_STextDirectionBottom = 1 << 2,
  A_STextDirectionLeft   = 1 << 3,
};

/**
 The trunction type, tells the truncation engine which type of truncation is being requested.
 */
typedef NS_ENUM (NSUInteger, A_STextTruncationType) {
  /// No truncate.
  A_STextTruncationTypeNone   = 0,
  
  /// Truncate at the beginning of the line, leaving the end portion visible.
  A_STextTruncationTypeStart  = 1,
  
  /// Truncate at the end of the line, leaving the start portion visible.
  A_STextTruncationTypeEnd    = 2,
  
  /// Truncate in the middle of the line, leaving both the start and the end portions visible.
  A_STextTruncationTypeMiddle = 3,
};



#pragma mark - Attribute Name Defined in A_SText

/// The value of this attribute is a `A_STextBackedString` object.
/// Use this attribute to store the original plain text if it is replaced by something else (such as attachment).
UIKIT_EXTERN NSString *const A_STextBackedStringAttributeName;

/// The value of this attribute is a `A_STextBinding` object.
/// Use this attribute to bind a range of text together, as if it was a single charactor.
UIKIT_EXTERN NSString *const A_STextBindingAttributeName;

/// The value of this attribute is a `A_STextShadow` object.
/// Use this attribute to add shadow to a range of text.
/// Shadow will be drawn below text glyphs. Use A_STextShadow.subShadow to add multi-shadow.
UIKIT_EXTERN NSString *const A_STextShadowAttributeName;

/// The value of this attribute is a `A_STextShadow` object.
/// Use this attribute to add inner shadow to a range of text.
/// Inner shadow will be drawn above text glyphs. Use A_STextShadow.subShadow to add multi-shadow.
UIKIT_EXTERN NSString *const A_STextInnerShadowAttributeName;

/// The value of this attribute is a `A_STextDecoration` object.
/// Use this attribute to add underline to a range of text.
/// The underline will be drawn below text glyphs.
UIKIT_EXTERN NSString *const A_STextUnderlineAttributeName;

/// The value of this attribute is a `A_STextDecoration` object.
/// Use this attribute to add strikethrough (delete line) to a range of text.
/// The strikethrough will be drawn above text glyphs.
UIKIT_EXTERN NSString *const A_STextStrikethroughAttributeName;

/// The value of this attribute is a `A_STextBorder` object.
/// Use this attribute to add cover border or cover color to a range of text.
/// The border will be drawn above the text glyphs.
UIKIT_EXTERN NSString *const A_STextBorderAttributeName;

/// The value of this attribute is a `A_STextBorder` object.
/// Use this attribute to add background border or background color to a range of text.
/// The border will be drawn below the text glyphs.
UIKIT_EXTERN NSString *const A_STextBackgroundBorderAttributeName;

/// The value of this attribute is a `A_STextBorder` object.
/// Use this attribute to add a code block border to one or more line of text.
/// The border will be drawn below the text glyphs.
UIKIT_EXTERN NSString *const A_STextBlockBorderAttributeName;

/// The value of this attribute is a `A_STextAttachment` object.
/// Use this attribute to add attachment to text.
/// It should be used in conjunction with a CTRunDelegate.
UIKIT_EXTERN NSString *const A_STextAttachmentAttributeName;

/// The value of this attribute is a `A_STextHighlight` object.
/// Use this attribute to add a touchable highlight state to a range of text.
UIKIT_EXTERN NSString *const A_STextHighlightAttributeName;

/// The value of this attribute is a `NSValue` object stores CGAffineTransform.
/// Use this attribute to add transform to each glyph in a range of text.
UIKIT_EXTERN NSString *const A_STextGlyphTransformAttributeName;



#pragma mark - String Token Define

UIKIT_EXTERN NSString *const A_STextAttachmentToken; ///< Object replacement character (U+FFFC), used for text attachment.
UIKIT_EXTERN NSString *const A_STextTruncationToken; ///< Horizontal ellipsis (U+2026), used for text truncation  "…".



#pragma mark - Attribute Value Define

/**
 The tap/long press action callback defined in A_SText.
 
 @param containerView The text container view (such as A_SLabel/A_STextView).
 @param text          The whole text.
 @param range         The text range in `text` (if no range, the range.location is NSNotFound).
 @param rect          The text frame in `containerView` (if no data, the rect is CGRectNull).
 */
typedef void(^A_STextAction)(UIView *containerView, NSAttributedString *text, NSRange range, CGRect rect);


/**
 A_STextBackedString objects are used by the NSAttributedString class cluster
 as the values for text backed string attributes (stored in the attributed
 string under the key named A_STextBackedStringAttributeName).
 
 It may used for copy/paste plain text from attributed string.
 Example: If :) is replace by a custom emoji (such as😊), the backed string can be set to @":)".
 */
@interface A_STextBackedString : NSObject <NSCoding, NSCopying>
+ (instancetype)stringWithString:(nullable NSString *)string;
@property (nullable, nonatomic, copy) NSString *string; ///< backed string
@end


/**
 A_STextBinding objects are used by the NSAttributedString class cluster
 as the values for shadow attributes (stored in the attributed string under
 the key named A_STextBindingAttributeName).
 
 Add this to a range of text will make the specified characters 'binding together'.
 A_STextView will treat the range of text as a single character during text
 selection and edit.
 */
@interface A_STextBinding : NSObject <NSCoding, NSCopying>
+ (instancetype)bindingWithDeleteConfirm:(BOOL)deleteConfirm;
@property (nonatomic) BOOL deleteConfirm; ///< confirm the range when delete in A_STextView
@end


/**
 A_STextShadow objects are used by the NSAttributedString class cluster
 as the values for shadow attributes (stored in the attributed string under
 the key named A_STextShadowAttributeName or A_STextInnerShadowAttributeName).
 
 It's similar to `NSShadow`, but offers more options.
 */
@interface A_STextShadow : NSObject <NSCoding, NSCopying>
+ (instancetype)shadowWithColor:(nullable UIColor *)color offset:(CGSize)offset radius:(CGFloat)radius;

@property (nullable, nonatomic, strong) UIColor *color; ///< shadow color
@property (nonatomic) CGSize offset;                    ///< shadow offset
@property (nonatomic) CGFloat radius;                   ///< shadow blur radius
@property (nonatomic) CGBlendMode blendMode;            ///< shadow blend mode
@property (nullable, nonatomic, strong) A_STextShadow *subShadow;  ///< a sub shadow which will be added above the parent shadow

+ (instancetype)shadowWithNSShadow:(NSShadow *)nsShadow; ///< convert NSShadow to A_STextShadow
- (NSShadow *)nsShadow; ///< convert A_STextShadow to NSShadow
@end


/**
 A_STextDecorationLine objects are used by the NSAttributedString class cluster
 as the values for decoration line attributes (stored in the attributed string under
 the key named A_STextUnderlineAttributeName or A_STextStrikethroughAttributeName).
 
 When it's used as underline, the line is drawn below text glyphs;
 when it's used as strikethrough, the line is drawn above text glyphs.
 */
@interface A_STextDecoration : NSObject <NSCoding, NSCopying>
+ (instancetype)decorationWithStyle:(A_STextLineStyle)style;
+ (instancetype)decorationWithStyle:(A_STextLineStyle)style width:(nullable NSNumber *)width color:(nullable UIColor *)color;
@property (nonatomic) A_STextLineStyle style;                   ///< line style
@property (nullable, nonatomic, strong) NSNumber *width;       ///< line width (nil means automatic width)
@property (nullable, nonatomic, strong) UIColor *color;        ///< line color (nil means automatic color)
@property (nullable, nonatomic, strong) A_STextShadow *shadow;  ///< line shadow
@end


/**
 A_STextBorder objects are used by the NSAttributedString class cluster
 as the values for border attributes (stored in the attributed string under
 the key named A_STextBorderAttributeName or A_STextBackgroundBorderAttributeName).
 
 It can be used to draw a border around a range of text, or draw a background
 to a range of text.
 
 Example:
 ╭──────╮
 │ Text │
 ╰──────╯
 */
@interface A_STextBorder : NSObject <NSCoding, NSCopying>
+ (instancetype)borderWithLineStyle:(A_STextLineStyle)lineStyle lineWidth:(CGFloat)width strokeColor:(nullable UIColor *)color;
+ (instancetype)borderWithFillColor:(nullable UIColor *)color cornerRadius:(CGFloat)cornerRadius;
@property (nonatomic) A_STextLineStyle lineStyle;              ///< border line style
@property (nonatomic) CGFloat strokeWidth;                    ///< border line width
@property (nullable, nonatomic, strong) UIColor *strokeColor; ///< border line color
@property (nonatomic) CGLineJoin lineJoin;                    ///< border line join
@property (nonatomic) UIEdgeInsets insets;                    ///< border insets for text bounds
@property (nonatomic) CGFloat cornerRadius;                   ///< border corder radius
@property (nullable, nonatomic, strong) A_STextShadow *shadow; ///< border shadow
@property (nullable, nonatomic, strong) UIColor *fillColor;   ///< inner fill color
@end


/**
 A_STextAttachment objects are used by the NSAttributedString class cluster
 as the values for attachment attributes (stored in the attributed string under
 the key named A_STextAttachmentAttributeName).
 
 When display an attributed string which contains `A_STextAttachment` object,
 the content will be placed in text metric. If the content is `UIImage`,
 then it will be drawn to CGContext; if the content is `UIView` or `CALayer`,
 then it will be added to the text container's view or layer.
 */
@interface A_STextAttachment : NSObject<NSCoding, NSCopying>
+ (instancetype)attachmentWithContent:(nullable id)content;
@property (nullable, nonatomic, strong) id content;             ///< Supported type: UIImage, UIView, CALayer
@property (nonatomic) UIViewContentMode contentMode;            ///< Content display mode.
@property (nonatomic) UIEdgeInsets contentInsets;               ///< The insets when drawing content.
@property (nullable, nonatomic, strong) NSDictionary *userInfo; ///< The user information dictionary.
@end


/**
 A_STextHighlight objects are used by the NSAttributedString class cluster
 as the values for touchable highlight attributes (stored in the attributed string
 under the key named A_STextHighlightAttributeName).
 
 When display an attributed string in `A_SLabel` or `A_STextView`, the range of
 highlight text can be toucheds down by users. If a range of text is turned into
 highlighted state, the `attributes` in `A_STextHighlight` will be used to modify
 (set or remove) the original attributes in the range for display.
 */
@interface A_STextHighlight : NSObject <NSCopying>

/**
 Attributes that you can apply to text in an attributed string when highlight.
 Key:   Same as CoreText/A_SText Attribute Name.
 Value: Modify attribute value when highlight (NSNull for remove attribute).
 */
@property (nullable, nonatomic, copy) NSDictionary<NSString *, id> *attributes;

/**
 Creates a highlight object with specified attributes.
 
 @param attributes The attributes which will replace original attributes when highlight,
 If the value is NSNull, it will removed when highlight.
 */
+ (instancetype)highlightWithAttributes:(nullable NSDictionary<NSString *, id> *)attributes;

/**
 Convenience methods to create a default highlight with the specifeid background color.
 
 @param color The background border color.
 */
+ (instancetype)highlightWithBackgroundColor:(nullable UIColor *)color;

// Convenience methods below to set the `attributes`.
- (void)setFont:(nullable UIFont *)font;
- (void)setColor:(nullable UIColor *)color;
- (void)setStrokeWidth:(nullable NSNumber *)width;
- (void)setStrokeColor:(nullable UIColor *)color;
- (void)setShadow:(nullable A_STextShadow *)shadow;
- (void)setInnerShadow:(nullable A_STextShadow *)shadow;
- (void)setUnderline:(nullable A_STextDecoration *)underline;
- (void)setStrikethrough:(nullable A_STextDecoration *)strikethrough;
- (void)setBackgroundBorder:(nullable A_STextBorder *)border;
- (void)setBorder:(nullable A_STextBorder *)border;
- (void)setAttachment:(nullable A_STextAttachment *)attachment;

/**
 The user information dictionary, default is nil.
 */
@property (nullable, nonatomic, copy) NSDictionary *userInfo;

/**
 Tap action when user tap the highlight, default is nil.
 If the value is nil, A_STextView or A_SLabel will ask it's delegate to handle the tap action.
 */
@property (nullable, nonatomic, copy) A_STextAction tapAction;

/**
 Long press action when user long press the highlight, default is nil.
 If the value is nil, A_STextView or A_SLabel will ask it's delegate to handle the long press action.
 */
@property (nullable, nonatomic, copy) A_STextAction longPressAction;

@end

NS_ASSUME_NONNULL_END
