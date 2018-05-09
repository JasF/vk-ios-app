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

let kBubblesSpacing: CGFloat = 6
let kGreatestBubbleWidthFraction: CGFloat = 0.72
let kBubblesMargin: CGFloat = 10
let kMediaNodeMargin: CGFloat = 6

public protocol BaseMessageCollectionViewCellStyleProtocol {
    func avatarSize(viewModel: MessageViewModelProtocol) -> CGSize // .zero => no avatar
    func avatarVerticalAlignment(viewModel: MessageViewModelProtocol) -> VerticalAlignment
    var failedIcon: UIImage { get }
    var failedIconHighlighted: UIImage { get }
    var selectionIndicatorMargins: UIEdgeInsets { get }
    func selectionIndicatorIcon(for viewModel: MessageViewModelProtocol) -> UIImage
    func attributedStringForDate(_ date: String) -> NSAttributedString
    func layoutConstants(viewModel: MessageViewModelProtocol) -> BaseMessageCollectionViewCellLayoutConstants
    var unreadBackgroundColor: UIColor { get }
    var readedBackgroundColor: UIColor { get }
}

public struct BaseMessageCollectionViewCellLayoutConstants {
    public let horizontalMargin: CGFloat
    public let horizontalInterspacing: CGFloat
    public let horizontalTimestampMargin: CGFloat
    public let maxContainerWidthPercentageForBubbleView: CGFloat

    public init(horizontalMargin: CGFloat,
                horizontalInterspacing: CGFloat,
                horizontalTimestampMargin: CGFloat,
                maxContainerWidthPercentageForBubbleView: CGFloat) {
        self.horizontalMargin = horizontalMargin
        self.horizontalInterspacing = horizontalInterspacing
        self.horizontalTimestampMargin = horizontalTimestampMargin
        self.maxContainerWidthPercentageForBubbleView = maxContainerWidthPercentageForBubbleView
    }
}

/**
    Base class for message cells

    Provides:

        - Reveleable timestamp
        - Failed icon
        - Incoming/outcoming styles
        - Selection support

    Subclasses responsability
        - Implement createBubbleView
        - Have a BubbleViewType that responds properly to sizeThatFits:
*/

open class BaseMessageCollectionViewCell<BubbleViewType>: ChatBaseNodeCell, BackgroundSizingQueryable, AccessoryViewRevealable, UIGestureRecognizerDelegate where
    BubbleViewType: ASDisplayNode,
    BubbleViewType: MaximumLayoutWidthSpecificable,
    BubbleViewType: BackgroundSizingQueryable,
    BubbleViewType: BaseBubbleViewProtocol {

    public override init() {
        super.init()
        commonInit()
    }
    open var nodeFactory: NodeFactory? = nil
    public var animationDuration: CFTimeInterval = 0.33
    open var viewContext: ViewContext = .normal

    public private(set) var isUpdating: Bool = false
    open func performBatchUpdates(_ updateClosure: @escaping () -> Void, animated: Bool, completion: (() -> Void)?) {
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

    override open func performUpdate() {
        self.updateViews()
    }
    
    func attributesUid(_ atts: [Attachments]) -> String {
        var uid = ""
        for att in atts {
            uid += att.uid()
        }
        return uid
    }
    
    var mediaNodes = [ASDisplayNode]()
    var mediaNodesUid = ""
    open var messageViewModel: MessageViewModelProtocol! {
        didSet {
            messageViewModel.node = self
            mediaNodes.removeAll()
            if let nodeFactory = self.nodeFactory {
                if let message = messageViewModel.message {
                    var uid = ""
                    if let atts = message.photoAttachments {
                        uid += attributesUid(atts)
                    }
                    if let atts = message.attachments {
                        uid += attributesUid(atts)
                    }
                    if uid.count == 0 {
                        return
                    }
                    if mediaNodesUid == uid {
                        return;
                    }
                    mediaNodesUid = uid
                    
                    let block: (Any) -> Void = { (att) in
                        if let node = nodeFactory.node(forItem: att) {
                            if let imagesNode = node as? PostImagesNode {
                                imagesNode.tappedOnPhotoHandler = { [weak self] (index) in
                                    guard let sSelf = self else { return }
                                    sSelf.onPhotoTapped?(sSelf, index)
                                }
                            }
                            else if let videoNode = node as? PostVideoNode {
                                videoNode.tappedOnVideoHandler = { [weak self] (video) in
                                    guard let sSelf = self else { return }
                                    sSelf.onVideoTapped?(sSelf, video!)
                                }
                            }
                            self.mediaNodes.append(node)
                        }
                    }
                    
                    if let atts = message.photoAttachments {
                        block(atts)
                    }
                    if let atts = message.attachments {
                        for att in atts {
                            block(att)
                        }
                    }
                }
            }
            self.bubbleView.mediaNodes = mediaNodes
            self.updateViews()
        }
    }

    public var baseStyle: BaseMessageCollectionViewCellStyleProtocol! {
        didSet {
            self.updateViews()
        }
    }
    private var shouldShowFailedIcon: Bool {
        return self.messageViewModel?.decorationAttributes.canShowFailedIcon == true && self.messageViewModel?.isShowingFailedIcon == true
    }

    override open var isSelected: Bool {
        didSet {
            if oldValue != self.isSelected {
                self.updateViews()
            }
        }
    }

    open var canCalculateSizeInBackground: Bool {
        return self.bubbleView.canCalculateSizeInBackground
    }

    public private(set) var bubbleView: BubbleViewType!
    open func createBubbleView() -> BubbleViewType! {
        assert(false, "Override in subclass")
        return nil
    }

    public private(set) var avatarView: ASImageNode!
    func createAvatarView() -> ASImageNode! {
        let avatarImageView = ASImageNode()//UIImageView(frame: CGRect.zero)
        avatarImageView.isUserInteractionEnabled = true
        return avatarImageView
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required public override init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    public private(set) lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BaseMessageCollectionViewCell.bubbleTapped(_:)))
        return tapGestureRecognizer
    }()

    public private (set) lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let longpressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(BaseMessageCollectionViewCell.bubbleLongPressed(_:)))
        longpressGestureRecognizer.delegate = self
        return longpressGestureRecognizer
    }()

    public private(set) lazy var avatarTapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BaseMessageCollectionViewCell.avatarTapped(_:)))
        return tapGestureRecognizer
    }()
    
    override open func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        //let layout = self.calculateLayout(availableWidth: constrainedSize.max.width)
        self.bubbleView.style.flexShrink = 1
        var array = [ASLayoutElement]()
        let insetSpec = ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(kBubblesSpacing/2, 0, kBubblesSpacing/2, 0), child: self.bubbleView)
        insetSpec.style.flexShrink = 1
        let spacing = ASLayoutSpec()
        spacing.style.flexGrow = 1
        if self.messageViewModel.isIncoming {
            array.append(insetSpec)
            array.append(spacing)
        }
        else {
            array.append(spacing)
            array.append(insetSpec)
            if self.messageViewModel.isShowingFailedIcon {
                array.append(self.failedButton)
            }
        }
        
        self.bubbleView.style.maxSize = CGSize(width: constrainedSize.max.width*kGreatestBubbleWidthFraction, height: constrainedSize.max.height)
        let horSpec = ASStackLayoutSpec.init(direction: .horizontal, spacing: 0, justifyContent: .start, alignItems: .center, children: array)
        return ASInsetLayoutSpec(insets: UIEdgeInsetsMake(0, kBubblesMargin, 0, kBubblesMargin), child: horSpec)
    }
    
    private func commonInit() {
        self.avatarView = self.createAvatarView()
        //self.avatarView.addGestureRecognizer(self.avatarTapGestureRecognizer)
        self.bubbleView = self.createBubbleView()
        self.bubbleView.isExclusiveTouch = true
        //NSLog("!")
        //self.bubbleView.addGestureRecognizer(self.tapGestureRecognizer)
        //self.bubbleView.addGestureRecognizer(self.longPressGestureRecognizer)
        //self.contentView.addSubview(self.avatarView)
        //self.contentView.addSubview(self.bubbleView)
        self.addSubnode(self.bubbleView)
        self.addSubnode(self.failedButton)
        //self.contentView.addSubview(self.failedButton)
        //self.contentView.addSubview(self.selectionIndicator)
        self.contentView.isExclusiveTouch = true
        self.isExclusiveTouch = true

        let selectionTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSelectionTap(_:)))
        self.selectionTapGestureRecognizer = selectionTapGestureRecognizer
        self.addGestureRecognizer(selectionTapGestureRecognizer)
    }

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        //NSLog("!")
        return false //self.bubbleView.bounds.contains(touch.location(in: self.bubbleView))
    }

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer === self.longPressGestureRecognizer
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        self.removeAccessoryView()
    }

    public private(set) lazy var failedButton: ASButtonNode = {
        let button = ASButtonNode()
        button.addTarget(self, action: #selector(BaseMessageCollectionViewCell.failedButtonTapped), forControlEvents: .touchUpInside)
        button.style.spacingBefore = 12
        button.style.spacingAfter = 12
        //button.style.width = ASDimensionMake(40)
        //button.style.height = ASDimensionMake(40)
        return button
    }()

    // MARK: View model binding

    final private func updateViews() {
        if self.viewContext == .sizing { return }
        if self.isUpdating { return }
        guard let viewModel = self.messageViewModel, let style = self.baseStyle else { return }
        self.bubbleView.isUserInteractionEnabled = viewModel.isUserInteractionEnabled
        if self.shouldShowFailedIcon {
            self.failedButton.setImage(self.baseStyle.failedIcon, for: .normal)
            self.failedButton.setImage(self.baseStyle.failedIconHighlighted, for: .highlighted)
            self.failedButton.alpha = 1
        } else {
            self.failedButton.alpha = 0
        }
        if self.messageViewModel.readState == 0 {
            self.backgroundColor = style.unreadBackgroundColor
        }
        else {
            self.backgroundColor = style.readedBackgroundColor
        }
        //self.accessoryTimestampView.attributedText = style.attributedStringForDate(viewModel.date)
        self.updateAvatarView(from: viewModel, with: style)
        self.updateSelectionIndicator(with: style)

        self.contentView.isUserInteractionEnabled = !viewModel.decorationAttributes.isShowingSelectionIndicator
        self.selectionTapGestureRecognizer?.isEnabled = viewModel.decorationAttributes.isShowingSelectionIndicator

        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    private func updateAvatarView(from viewModel: MessageViewModelProtocol,
                                  with style: BaseMessageCollectionViewCellStyleProtocol) {
        self.avatarView.isHidden = !viewModel.decorationAttributes.isShowingAvatar

        let avatarImageSize = style.avatarSize(viewModel: viewModel)
        if avatarImageSize != .zero {
            self.avatarView.image = viewModel.avatarImage.value
        }
    }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return self.calculateLayout(availableWidth: size.width).size
    }

    private func calculateLayout(availableWidth: CGFloat) -> Layout {
        let layoutConstants = baseStyle.layoutConstants(viewModel: messageViewModel)
        let parameters = LayoutParameters(
            containerWidth: availableWidth,
            horizontalMargin: layoutConstants.horizontalMargin,
            horizontalInterspacing: layoutConstants.horizontalInterspacing,
            maxContainerWidthPercentageForBubbleView: layoutConstants.maxContainerWidthPercentageForBubbleView,
            bubbleView: self.bubbleView,
            isIncoming: self.messageViewModel.isIncoming,
            isShowingFailedButton: self.shouldShowFailedIcon,
            failedButtonSize: self.baseStyle.failedIcon.size,
            avatarSize: self.baseStyle.avatarSize(viewModel: self.messageViewModel),
            avatarVerticalAlignment: self.baseStyle.avatarVerticalAlignment(viewModel: self.messageViewModel),
            isShowingSelectionIndicator: self.messageViewModel.decorationAttributes.isShowingSelectionIndicator,
            selectionIndicatorSize: self.baseStyle.selectionIndicatorIcon(for: self.messageViewModel).size,
            selectionIndicatorMargins: self.baseStyle.selectionIndicatorMargins
        )
        var layoutModel = Layout()
        layoutModel.calculateLayout(parameters: parameters)
        return layoutModel
    }

    // MARK: timestamp revealing

    private let accessoryTimestampView = ChatBaseNodeCellInternal()

    var offsetToRevealAccessoryView: CGFloat = 0 {
        didSet {
            self.setNeedsLayout()
        }
    }

    public var allowAccessoryViewRevealing: Bool = true

    open func preferredOffsetToRevealAccessoryView() -> CGFloat? {
        let layoutConstants = baseStyle.layoutConstants(viewModel: messageViewModel)
        return 0//self.accessoryTimestampView.intrinsicContentSize.width + layoutConstants.horizontalTimestampMargin
    }

    open func revealAccessoryView(withOffset offset: CGFloat, animated: Bool) {
        self.offsetToRevealAccessoryView = offset
        /*
        if self.accessoryTimestampView.superview == nil {
            if offset > 0 {
                self.addSubview(self.accessoryTimestampView)
                self.layoutIfNeeded()
            }

            if animated {
                UIView.animate(withDuration: self.animationDuration, animations: { () -> Void in
                    self.layoutIfNeeded()
                })
            }
        } else {
            if animated {
                UIView.animate(withDuration: self.animationDuration, animations: { () -> Void in
                    self.layoutIfNeeded()
                    }, completion: { (_) -> Void in
                        if offset == 0 {
                            self.removeAccessoryView()
                        }
                })
            }
        }
 */
    }

    func removeAccessoryView() {
        //self.accessoryTimestampView.removeFromSuperview()
    }

    // MARK: Selection

    private let selectionIndicator = ASImageNode() //UIImageView(frame: .zero)

    private func updateSelectionIndicator(with style: BaseMessageCollectionViewCellStyleProtocol) {
        self.selectionIndicator.image = style.selectionIndicatorIcon(for: self.messageViewModel)
        self.updateSelectionIndicatorAccessibilityIdentifier()
    }

    private var selectionTapGestureRecognizer: UITapGestureRecognizer?
    public var onSelection: ((_ cell: BaseMessageCollectionViewCell) -> Void)?

    @objc
    private func handleSelectionTap(_ gestureRecognizer: UITapGestureRecognizer) {
        self.onSelection?(self)
    }

    private func updateSelectionIndicatorAccessibilityIdentifier() {
        let accessibilityIdentifier: String
        if self.messageViewModel.decorationAttributes.isShowingSelectionIndicator {
            if self.messageViewModel.decorationAttributes.isSelected {
                accessibilityIdentifier = "chat.message.selection_indicator.selected"
            } else {
                accessibilityIdentifier = "chat.message.selection_indicator.deselected"
            }
        } else {
            accessibilityIdentifier = "chat.message.selection_indicator.hidden"
        }
        self.selectionIndicator.accessibilityIdentifier = accessibilityIdentifier
    }

    // MARK: User interaction

    public var onFailedButtonTapped: ((_ cell: BaseMessageCollectionViewCell) -> Void)?
    public var onPhotoTapped: ((_ cell: BaseMessageCollectionViewCell, _ index: Int) -> Void)?
    public var onVideoTapped: ((_ cell: BaseMessageCollectionViewCell, _ video: Video) -> Void)?
    @objc
    func failedButtonTapped() {
        self.onFailedButtonTapped?(self)
    }

    public var onAvatarTapped: ((_ cell: BaseMessageCollectionViewCell) -> Void)?
    @objc
    func avatarTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
        self.onAvatarTapped?(self)
    }

    public var onBubbleTapped: ((_ cell: BaseMessageCollectionViewCell) -> Void)?
    @objc
    func bubbleTapped(_ tapGestureRecognizer: UITapGestureRecognizer) {
        self.onBubbleTapped?(self)
    }

    public var onBubbleLongPressBegan: ((_ cell: BaseMessageCollectionViewCell) -> Void)?
    public var onBubbleLongPressEnded: ((_ cell: BaseMessageCollectionViewCell) -> Void)?
    @objc
    private func bubbleLongPressed(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        switch longPressGestureRecognizer.state {
        case .began:
            self.onBubbleLongPressBegan?(self)
        case .ended, .cancelled:
            self.onBubbleLongPressEnded?(self)
        default:
            break
        }
    }
}

fileprivate struct Layout {
    private (set) var size = CGSize.zero
    private (set) var failedButtonFrame = CGRect.zero
    private (set) var bubbleViewFrame = CGRect.zero
    private (set) var avatarViewFrame = CGRect.zero
    private (set) var selectionIndicatorFrame = CGRect.zero
    private (set) var preferredMaxWidthForBubble: CGFloat = 0

    mutating func calculateLayout(parameters: LayoutParameters) {
        let containerWidth = parameters.containerWidth
        let isIncoming = parameters.isIncoming
        let isShowingFailedButton = false//parameters.isShowingFailedButton
        let failedButtonSize = parameters.failedButtonSize
        let bubbleView = parameters.bubbleView
        let horizontalMargin = parameters.horizontalMargin
        let horizontalInterspacing = parameters.horizontalInterspacing
        let avatarSize = CGSize(width: 0, height: 0) //parameters.avatarSize
        let selectionIndicatorSize = parameters.selectionIndicatorSize

        let preferredWidthForBubble = (containerWidth * parameters.maxContainerWidthPercentageForBubbleView).bma_round()
        let bubbleSize = CGSize(width: preferredWidthForBubble, height: 10)//bubbleView.sizeThatFits(CGSize(width: preferredWidthForBubble, height: .greatestFiniteMagnitude))
        let containerRect = CGRect(origin: CGPoint.zero, size: CGSize(width: containerWidth, height: bubbleSize.height))

        self.bubbleViewFrame = bubbleSize.bma_rect(
            inContainer: containerRect,
            xAlignament: .center,
            yAlignment: .center
        )

        self.failedButtonFrame = failedButtonSize.bma_rect(
            inContainer: containerRect,
            xAlignament: .center,
            yAlignment: .center
        )

        self.avatarViewFrame = avatarSize.bma_rect(
            inContainer: containerRect,
            xAlignament: .center,
            yAlignment: parameters.avatarVerticalAlignment
        )

        self.selectionIndicatorFrame = selectionIndicatorSize.bma_rect(
            inContainer: containerRect,
            xAlignament: .left,
            yAlignment: .center
        )

        // Adjust horizontal positions

        var currentX: CGFloat = 0

        if parameters.isShowingSelectionIndicator {
            self.selectionIndicatorFrame.origin.x += parameters.selectionIndicatorMargins.left
        } else {
            self.selectionIndicatorFrame.origin.x -= selectionIndicatorSize.width
        }

        currentX += self.selectionIndicatorFrame.maxX

        if isIncoming {
            currentX += horizontalMargin
            self.avatarViewFrame.origin.x = currentX
            currentX += avatarSize.width
            if isShowingFailedButton {
                currentX += horizontalInterspacing
                self.failedButtonFrame.origin.x = currentX
                currentX += failedButtonSize.width
                currentX += horizontalInterspacing
            } else {
                self.failedButtonFrame.origin.x = currentX - failedButtonSize.width
                currentX += horizontalInterspacing
            }
            self.bubbleViewFrame.origin.x = currentX
        } else {
            currentX = containerRect.maxX - horizontalMargin
            currentX -= avatarSize.width
            self.avatarViewFrame.origin.x = currentX
            if isShowingFailedButton {
                currentX -= horizontalInterspacing
                currentX -= failedButtonSize.width
                self.failedButtonFrame.origin.x = currentX
                currentX -= horizontalInterspacing
            } else {
                self.failedButtonFrame.origin.x = currentX
                currentX -= horizontalInterspacing
            }
            currentX -= bubbleSize.width
            self.bubbleViewFrame.origin.x = currentX
        }

        self.size = containerRect.size
        self.preferredMaxWidthForBubble = preferredWidthForBubble
    }
}

fileprivate struct LayoutParameters {
    let containerWidth: CGFloat
    let horizontalMargin: CGFloat
    let horizontalInterspacing: CGFloat
    let maxContainerWidthPercentageForBubbleView: CGFloat // in [0, 1]
    let bubbleView: ASDisplayNode
    let isIncoming: Bool
    let isShowingFailedButton: Bool
    let failedButtonSize: CGSize
    let avatarSize: CGSize
    let avatarVerticalAlignment: VerticalAlignment
    let isShowingSelectionIndicator: Bool
    let selectionIndicatorSize: CGSize
    let selectionIndicatorMargins: UIEdgeInsets
}
