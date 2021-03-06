/*
 The MIT License (MIT)

 Copyright (c) 2015-present Badoo Trading Limited.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

import UIKit

import AsyncDisplayKit

public protocol TextBubbleViewStyleProtocol {
    func bubbleImage(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIImage
    func bubbleImageBorder(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIImage?
    func textFont(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIFont
    func textColor(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIColor
    func textInsets(viewModel: TextMessageViewModelProtocol, isSelected: Bool) -> UIEdgeInsets
}

public final class TextBubbleView: ASDisplayNode, MaximumLayoutWidthSpecificable, BackgroundSizingQueryable, BaseBubbleViewProtocol {
    let kBaseInsetValue: CGFloat = 6
    let kTileInsetValue: CGFloat = 13
    let textNode = ASTextNode()
    var _mediaNodes: [ASDisplayNode]? = nil
    public var mediaNodes:[ASDisplayNode]?  {
        get {
            return _mediaNodes
        }
        set {
            if let array = _mediaNodes {
                for node in array {
                    node.removeFromSupernode()
                }
            }
            _mediaNodes = newValue
            if let array = _mediaNodes {
                for node in array {
                    self.addSubnode(node)
                    if node.isKind(of: WallPostNode.self) || node.isKind(of: PostVideoNode.self) {
                        node.backgroundColor = UIColor.white
                    }
                }
            }
        }
    }
    public func disableBackground() {
        self.bubbleImageView.alpha = 0.0
    }
    
    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var spec: ASLayoutSpec? = ASInsetLayoutSpec.init(insets: textInsets, child: textNode)
        if let mediaNodes = self.mediaNodes {
            if mediaNodes.count > 0 {
                var mediaSpecs = [ASLayoutElement]()
                if (textNode.attributedText?.string.count)! > 0 {
                    mediaSpecs.append(ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(4, 0, 4, 0), child: textNode))
                }
                for node in mediaNodes {
                    mediaSpecs.append(node)
                }
                spec = ASStackLayoutSpec(direction: .vertical, spacing: kMediaNodeMargin, justifyContent: .start, alignItems: .start, children: mediaSpecs)
                var inset:UIEdgeInsets? = nil
                if textMessageViewModel.isIncoming {
                    inset = UIEdgeInsetsMake(kBaseInsetValue, kTileInsetValue, kBaseInsetValue, kBaseInsetValue)
                }
                else {
                    inset = UIEdgeInsetsMake(kBaseInsetValue, kBaseInsetValue, kBaseInsetValue, kTileInsetValue)
                }
                spec = ASInsetLayoutSpec(insets: inset!, child: spec!)
            }
        }
        
        let bgspec = ASBackgroundLayoutSpec.init(child: spec!, background: self.bubbleImageView)
        return bgspec
    }
    public var preferredMaxLayoutWidth: CGFloat = 0
    public var animationDuration: CFTimeInterval = 0.33
    public var viewContext: ViewContext = .normal {
        didSet {
            if self.viewContext == .sizing {
                //self.textView.dataDetectorTypes = UIDataDetectorTypes()
                //self.textView.isSelectable = false
            } else {
                //self.textView.dataDetectorTypes = .all
                //self.textView.isSelectable = true
            }
        }
    }

    public var viewStyle: TextBubbleViewStyleProtocol! {
        didSet {
            self.updateViews()
        }
    }

    public var textMessageViewModel: TextMessageViewModelProtocol! {
        didSet {
            self.updateViews()
        }
    }

    public var isSelected: Bool = false {
        didSet {
            if self.isSelected != oldValue {
                self.updateViews()
            }
        }
    }

    override init() {
        super.init()
        self.commonInit()
    }

    private func commonInit() {
        self.addSubnode(self.bubbleImageView)
        self.addSubnode(textNode)
        //self.addSubview(self.bubbleImageView)
        //self.addSubview(self.textView)
    }

    private lazy var bubbleImageView: ASImageNode = {
        let imageView = ASImageNode()
        //imageView.addSubview(self.borderImageView)
        return imageView
    }()

    private var borderImageView: ASImageNode = ASImageNode()
    private var textView: ChatMessageTextView = {
        let textView = ChatMessageTextView()
        /*
        UIView.performWithoutAnimation({ () -> Void in // fixes iOS 8 blinking when cell appears
            textView.backgroundColor = UIColor.clear
        })
        textView.isEditable = false
        textView.isSelectable = true
        textView.dataDetectorTypes = .all
        textView.scrollsToTop = false
        textView.isScrollEnabled = false
        textView.bounces = false
        textView.bouncesZoom = false
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.isExclusiveTouch = true
        textView.textContainer.lineFragmentPadding = 0
 */
        return textView
    }()

    public private(set) var isUpdating: Bool = false
    public func performBatchUpdates(_ updateClosure: @escaping () -> Void, animated: Bool, completion: (() -> Void)?) {
        self.isUpdating = true
        let updateAndRefreshViews = {
            updateClosure()
            self.isUpdating = false
            self.updateViews()
            if animated {
                self.layoutIfNeeded()
            }
        }
        if animated {
            ChatAnimation.chatAnimation(withDuration: self.animationDuration, animations: updateAndRefreshViews, completion: { (_) -> Void in
                completion?()
            })
        } else {
            updateAndRefreshViews()
        }
    }

    private func updateViews() {
        if self.viewContext == .sizing { return }
        if isUpdating { return }
        guard let style = self.viewStyle else { return }

        self.updateTextView()
        
        let bubbleImage = style.bubbleImage(viewModel: self.textMessageViewModel, isSelected: self.isSelected)
        let borderImage = style.bubbleImageBorder(viewModel: self.textMessageViewModel, isSelected: self.isSelected)
        if self.bubbleImageView.image != bubbleImage { self.bubbleImageView.image = bubbleImage }
        if self.borderImageView.image != borderImage { self.borderImageView.image = borderImage }
 
    }

    var font: UIFont?
    var textColor: UIColor?
    var text: String?
    var textInsets = UIEdgeInsetsMake(0, 0, 0, 0)
    
    private func updateTextView() {
        guard let style = self.viewStyle, let viewModel = self.textMessageViewModel else { return }

        let font = style.textFont(viewModel: viewModel, isSelected: self.isSelected)
        let textColor = style.textColor(viewModel: viewModel, isSelected: self.isSelected)

        var needsToUpdateText = false
        
        if self.font != font {
            self.font = font
            needsToUpdateText = true
        }

        if self.textColor != textColor {
            self.textColor = textColor
            needsToUpdateText = true
        }
        

        if needsToUpdateText || self.text != viewModel.text {
            
            let attrs = [ NSAttributedStringKey.foregroundColor: textColor,
                          NSAttributedStringKey.font: font ]
            self.textNode.attributedText = NSAttributedString.init(string: viewModel.text, attributes: attrs)
            
            self.setNeedsLayout()
        }

       textInsets = style.textInsets(viewModel: viewModel, isSelected: self.isSelected)
       // if self.textView.textContainerInset != textInsets { self.textView.textContainerInset = textInsets }
    }

    private func bubbleImage() -> UIImage {
        return self.viewStyle.bubbleImage(viewModel: self.textMessageViewModel, isSelected: self.isSelected)
    }

    public func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.calculateTextBubbleLayout(preferredMaxLayoutWidth: size.width).size
    }

    // MARK: Layout
    public func layoutSubviews() {
       // super.layoutSubviews()
        //let layout = self.calculateTextBubbleLayout(preferredMaxLayoutWidth: self.preferredMaxLayoutWidth)
       // self.textView.bma_rect = layout.textFrame
        //self.bubbleImageView.bma_rect = layout.bubbleFrame
        //self.borderImageView.bma_rect = self.bubbleImageView.bounds
    }

    public var layoutCache: NSCache<AnyObject, AnyObject>!
    private func calculateTextBubbleLayout(preferredMaxLayoutWidth: CGFloat) -> TextBubbleLayoutModel {
        let layoutContext = TextBubbleLayoutModel.LayoutContext(
            text: self.textMessageViewModel.text,
            font: self.viewStyle.textFont(viewModel: self.textMessageViewModel, isSelected: self.isSelected),
            textInsets: self.viewStyle.textInsets(viewModel: self.textMessageViewModel, isSelected: self.isSelected),
            preferredMaxLayoutWidth: preferredMaxLayoutWidth
        )

        if let layoutModel = self.layoutCache.object(forKey: layoutContext.hashValue as AnyObject) as? TextBubbleLayoutModel, layoutModel.layoutContext == layoutContext {
            return layoutModel
        }

        let layoutModel = TextBubbleLayoutModel(layoutContext: layoutContext)
        layoutModel.calculateLayout()

        self.layoutCache.setObject(layoutModel, forKey: layoutContext.hashValue as AnyObject)
        return layoutModel
    }

    public var canCalculateSizeInBackground: Bool {
        return true
    }
}

private final class TextBubbleLayoutModel {
    let layoutContext: LayoutContext
    var textFrame: CGRect = CGRect.zero
    var bubbleFrame: CGRect = CGRect.zero
    var size: CGSize = CGSize.zero

    init(layoutContext: LayoutContext) {
        self.layoutContext = layoutContext
    }

    struct LayoutContext: Equatable, Hashable {
        let text: String
        let font: UIFont
        let textInsets: UIEdgeInsets
        let preferredMaxLayoutWidth: CGFloat

        var hashValue: Int {
            return bma_combine(hashes: [self.text.hashValue, self.textInsets.bma_hashValue, self.preferredMaxLayoutWidth.hashValue, self.font.hashValue])
        }

        static func == (lhs: TextBubbleLayoutModel.LayoutContext, rhs: TextBubbleLayoutModel.LayoutContext) -> Bool {
            let lhsValues = (lhs.text, lhs.textInsets, lhs.font, lhs.preferredMaxLayoutWidth)
            let rhsValues = (rhs.text, rhs.textInsets, rhs.font, rhs.preferredMaxLayoutWidth)
            return lhsValues == rhsValues
        }
    }

    func calculateLayout() {
        let textHorizontalInset = self.layoutContext.textInsets.bma_horziontalInset
        let maxTextWidth = self.layoutContext.preferredMaxLayoutWidth - textHorizontalInset
        let textSize = self.textSizeThatFitsWidth(maxTextWidth)
        let bubbleSize = textSize.bma_outsetBy(dx: textHorizontalInset, dy: self.layoutContext.textInsets.bma_verticalInset)
        self.bubbleFrame = CGRect(origin: CGPoint.zero, size: bubbleSize)
        self.textFrame = self.bubbleFrame
        self.size = bubbleSize
    }

    private func textSizeThatFitsWidth(_ width: CGFloat) -> CGSize {
        let textContainer: NSTextContainer = {
            let size = CGSize(width: width, height: .greatestFiniteMagnitude)
            let container = NSTextContainer(size: size)
            container.lineFragmentPadding = 0
            return container
        }()

        let textStorage = self.replicateUITextViewNSTextStorage()
        let layoutManager: NSLayoutManager = {
            let layoutManager = NSLayoutManager()
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)
            return layoutManager
        }()

        let rect = layoutManager.usedRect(for: textContainer)
        return rect.size.bma_round()
    }

    private func replicateUITextViewNSTextStorage() -> NSTextStorage {
        // See https://github.com/badoo/Chatto/issues/129
        return NSTextStorage(string: self.layoutContext.text, attributes: [
            NSAttributedStringKey.font: self.layoutContext.font,
            NSAttributedStringKey(rawValue: "NSOriginalFont"): self.layoutContext.font
        ])
    }
}

/// UITextView with hacks to avoid selection, loupe, define...
private final class ChatMessageTextView: ASTextNode {

    var canBecomeFirstResponder: Bool {
        return false
    }

    // See https://github.com/badoo/Chatto/issues/363
    /*
    override var gestureRecognizers: [UIGestureRecognizer]? {
        set {
            super.gestureRecognizers = newValue
        }
        get {
            return super.gestureRecognizers?.filter({ (gestureRecognizer) -> Bool in
                return type(of: gestureRecognizer) == UILongPressGestureRecognizer.self && gestureRecognizer.delaysTouchesEnded
            })
        }
    }
*/
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return false
    }
/*
    override var selectedRange: NSRange {
        get {
            return NSRange(location: 0, length: 0)
        }
        set {
            // Part of the heaviest stack trace when scrolling (when updating text)
            // See https://github.com/badoo/Chatto/pull/144
        }
    }

    override var contentOffset: CGPoint {
        get {
            return .zero
        }
        set {
            // Part of the heaviest stack trace when scrolling (when bounds are set)
            // See https://github.com/badoo/Chatto/pull/144
        }
    }
 */
}
