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

class ChatTableNode : ASTableNode {
    override var contentInset: UIEdgeInsets {
        didSet {
            NSLog("contentInset:  \(contentInset)");
            NSLog("!");
        }
    }
}

@objcMembers class TableNodeHolder : ASDisplayNode {
    let tableNode = ChatTableNode()
    override init() {
        super.init()
        self.addSubnode(tableNode)
    }
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(0, 0, 0, 0), child:tableNode)
    }
}

open class BaseChatViewController: ChatInputBarViewController, ASTableDelegate, ASTableDataSource {
    
    

    public typealias ChatItemCompanionCollection = ReadOnlyOrderedDictionary<ChatItemCompanion>

    open var layoutConfiguration: ChatLayoutConfigurationProtocol = ChatLayoutConfiguration.defaultConfiguration {
        didSet {
            //self.adjustCollectionViewInsets(shouldUpdateContentOffset: false)
        }
    }

    open var tableNode : ASTableNode {
        get {
            return tableNodeHolder.tableNode
        }
    }
    let tableNodeHolder = TableNodeHolder()
    public init() {
        tableNodeHolder.tableNode.inverted = true
        super.init(node:tableNodeHolder)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public struct Constants {
        public var updatesAnimationDuration: TimeInterval = 0.33
        public var preferredMaxMessageCount: Int? = 500 // If not nil, will ask data source to reduce number of messages when limit is reached. @see ChatDataSourceDelegateProtocol
        public var preferredMaxMessageCountAdjustment: Int = 400 // When the above happens, will ask to adjust with this value. It may be wise for this to be smaller to reduce number of adjustments
        public var autoloadingFractionalThreshold: CGFloat = 0.05 // in [0, 1]
    }

    public var constants = Constants()

    public struct UpdatesConfig {
        public var fastUpdates = false // Allows another performBatchUpdates to be called before completion of a previous one (not recommended). Changing this value after viewDidLoad is not supported
        public var coalesceUpdates = false // If receiving data source updates too fast, while an update it's being processed, only the last one will be executed
    }

    public var updatesConfig =  UpdatesConfig()

    
    public final internal(set) var chatItemCompanionCollection: ChatItemCompanionCollection = ReadOnlyOrderedDictionary(items: [])
    private var _chatDataSource: ChatDataSourceProtocol?
    public final var chatDataSource: ChatDataSourceProtocol? {
        get {
            return _chatDataSource
        }
        set {
            self.setChatDataSource(newValue, triggeringUpdateType: .normal)
        }
    }

    // If set to false user is responsible to make sure that view provided in loadView() implements BaseChatViewContollerViewProtocol.
    // Must be set before loadView is called.
    public var substitutesMainViewAutomatically = true

    // Custom update on setting the data source. if triggeringUpdateType is nil it won't enqueue any update (you should do it later manually)
    public final func setChatDataSource(_ dataSource: ChatDataSourceProtocol?, triggeringUpdateType updateType: UpdateType?) {
        self._chatDataSource = dataSource
        self._chatDataSource?.delegate = self
        if let updateType = updateType {
            self.enqueueModelUpdate(updateType: updateType)
        }
    }

    deinit {
        self.tableNode.delegate = nil
        self.tableNode.dataSource = nil
    }

    let genericCollectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), collectionViewLayout:UICollectionViewFlowLayout.init())
    /*
    open override func loadView() {
        if substitutesMainViewAutomatically {
            self.view = BaseChatViewControllerView() // http://stackoverflow.com/questions/24596031/uiviewcontroller-with-inputaccessoryview-is-not-deallocated
            self.view.backgroundColor = UIColor.white
        } else {
            super.loadView()
        }

    }
    */

    override open func getTableNode() -> ASTableNode {
        return self.tableNode
    }
    override open func viewDidLoad() {
        super.viewDidLoad()
        self.addCollectionView()
        self.setupKeyboardTracker()
        self.setupTapGestureRecognizer()
    }

    private func setupTapGestureRecognizer() {
        NSLog("! missing gesture recognizer");
        /*
         
        self.collectionView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BaseChatViewController.userDidTapOnCollectionView)))
        */
    }

    public var endsEditingWhenTappingOnChatBackground = true
    @objc
    open func userDidTapOnCollectionView() {
        if self.endsEditingWhenTappingOnChatBackground {
            self.view.endEditing(true)
        }
    }

    private func addCollectionView() {
        NSLog("! addCollectionView createPresenterFactory");
        self.presenterFactory = self.createPresenterFactory()
        self.tableNode.delegate = self
        self.tableNode.dataSource = self
        //self.presenterFactory.configure(withCollectionView: self.collectionView)
    }

    var unfinishedBatchUpdatesCount: Int = 0
    var onAllBatchUpdatesFinished: (() -> Void)?

   // private var inputContainerBottomConstraint: NSLayoutConstraint!
   
    var collectionView : UITableView {
        get {
            return self.tableNode.view
        }
        set {
            
        }
    }

    var isAdjustingInputContainer: Bool = false
    open func setupKeyboardTracker() {
        let layoutBlock = { [weak self] (bottomMargin: CGFloat, keyboardStatus: KeyboardStatus) in
            guard let sSelf = self else { return }
            sSelf.handleKeyboardPositionChange(bottomMargin: bottomMargin, keyboardStatus: keyboardStatus)
        }


    }

    open func handleKeyboardPositionChange(bottomMargin: CGFloat, keyboardStatus: KeyboardStatus) {
        self.isAdjustingInputContainer = true
        self.view.layoutIfNeeded()
        self.isAdjustingInputContainer = false
    }

    var notificationCenter = NotificationCenter.default

    public private(set) var isFirstLayout: Bool = true
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        //self.adjustCollectionViewInsets(shouldUpdateContentOffset: true)

        if self.isFirstLayout {
            self.updateQueue.start()
            self.isFirstLayout = false
        }
    }

    public var allContentFits: Bool {
        /*
        let availableHeight = self.view.bounds.height - (insetTop + insetBottom)
        let contentSize = self.collectionView.collectionViewLayout.collectionViewContentSize
        return availableHeight >= contentSize.height
 */
        NSLog("! allContentFits")
        return false
    }

    func rectAtIndexPath(_ indexPath: IndexPath?) -> CGRect? {
        NSLog("! rectAtIndexPath")
        /*
        if let indexPath = indexPath {
            return self.collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame
        }
         */
        return nil
    }

    var autoLoadingEnabled: Bool = false
    var accessoryViewRevealer: AccessoryViewRevealer!
    var presenterFactory: ChatItemPresenterFactoryProtocol!
    let presentersByCell = NSMapTable<ChatBaseNodeCell, AnyObject>(keyOptions: .weakMemory, valueOptions: .weakMemory)
    var visibleCells: [IndexPath: ChatBaseNodeCell] = [:] // @see visibleCellsAreValid(changes:)

    public internal(set) var updateQueue: SerialTaskQueueProtocol = SerialTaskQueue()

    /**
     - You can use a decorator to:
        - Provide the ChatCollectionViewLayout with margins between messages
        - Provide to your pressenters additional attributes to help them configure their cells (for instance if a bubble should show a tail)
        - You can also add new items (for instance time markers or failed cells)
    */
    public var chatItemsDecorator: ChatItemsDecoratorProtocol?

    open func createCollectionViewLayout() -> UICollectionViewLayout {
        let layout = ChatCollectionViewLayout()
        layout.delegate = self
        return layout
    }

    var layoutModel = ChatCollectionViewLayoutModel.createModel(0, itemsLayoutData: [])

    // MARK: Subclass overrides

    open func createPresenterFactory() -> ChatItemPresenterFactoryProtocol {
        // Default implementation
        return ChatItemPresenterFactory(presenterBuildersByType: self.createPresenterBuilders())
    }

    open func createPresenterBuilders() -> [ChatItemType: [ChatItemPresenterBuilderProtocol]] {
        assert(false, "Override in subclass")
        return [ChatItemType: [ChatItemPresenterBuilderProtocol]]()
    }

    open func createChatInputView() -> UIView {
        assert(false, "Override in subclass")
        return UIView()
    }

    /**
        When paginating up we need to change the scroll position as the content is pushed down.
        We take distance to top from beforeUpdate indexPath and then we make afterUpdate indexPath to appear at the same distance
    */
    open func referenceIndexPathsToRestoreScrollPositionOnUpdate(itemsBeforeUpdate: ChatItemCompanionCollection, changes: CollectionChanges) -> (beforeUpdate: IndexPath?, afterUpdate: IndexPath?) {
        let firstItemMoved = changes.movedIndexPaths.first
        return (firstItemMoved?.indexPathOld as IndexPath?, firstItemMoved?.indexPathNew as IndexPath?)
    }
}

extension BaseChatViewController { // Rotation

    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        NSLog("! BaseChatViewController viewWillTransition")
        /*
        let shouldScrollToBottom = self.isScrolledAtBottom()
        let referenceIndexPath = self.collectionView.indexPathsForVisibleItems.first
        let oldRect = self.rectAtIndexPath(referenceIndexPath)
        coordinator.animate(alongsideTransition: { (_) -> Void in
            if shouldScrollToBottom {
                self.scrollToBottom(animated: false)
            } else {
                let newRect = self.rectAtIndexPath(referenceIndexPath)
                self.scrollToPreservePosition(oldRefRect: oldRect, newRefRect: newRect)
            }
        }, completion: nil)
         */
    }
}
