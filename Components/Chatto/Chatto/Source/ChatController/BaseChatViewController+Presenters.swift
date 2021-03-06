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

import Foundation
import AsyncDisplayKit

extension BaseChatViewController: ChatCollectionViewLayoutDelegate {
    public func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        //NSLog("number of pseudo-bubbles:\(self.chatItemCompanionCollection.count)")
        return self.chatItemCompanionCollection.count
    }
    public func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            let presenter = self.presenterForIndexPath(indexPath)
            if let model = presenter.getMessageModel() as! DemoTextMessageModel? {
                if let viewModel = model.viewModel {
                    if let node = viewModel.node {
                        return node
                    }
                }
            }
            let cell = presenter.dequeueCell(collectionView:self.genericCollectionView, indexPath: indexPath)
            let decorationAttributes = self.decorationAttributesForIndexPath(indexPath)
            presenter.configureCell(cell, decorationAttributes: decorationAttributes)
            cell.selectionStyle = .none
            return cell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.chatItemCompanionCollection.count
    }

    @objc(collectionView:cellForItemAtIndexPath:)
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> ChatBaseNodeCell {
        let presenter = self.presenterForIndexPath(indexPath)
        let cell = presenter.dequeueCell(collectionView: collectionView, indexPath: indexPath)
        let decorationAttributes = self.decorationAttributesForIndexPath(indexPath)
        presenter.configureCell(cell, decorationAttributes: decorationAttributes)
        return cell
    }

    @objc(collectionView:didEndDisplayingCell:forItemAtIndexPath:)
    open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: ChatBaseNodeCell, forItemAt indexPath: IndexPath) {
        // Carefull: this index path can refer to old data source after an update. Don't use it to grab items from the model
        // Instead let's use a mapping presenter <--> cell
        if let oldPresenterForCell = self.presentersByCell.object(forKey: cell) as? ChatItemPresenterProtocol {
            self.presentersByCell.removeObject(forKey: cell)
            oldPresenterForCell.cellWasHidden(cell)
        }

        if self.updatesConfig.fastUpdates {
            if let visibleCell = self.visibleCells[indexPath], visibleCell === cell {
                self.visibleCells[indexPath] = nil
            } else {
                self.visibleCells.forEach({ (indexPath, storedCell) in
                    if cell === storedCell {
                        // Inconsistency found, likely due to very fast updates
                        self.visibleCells[indexPath] = nil
                    }
                })
            }
        }
    }

    @objc open func tableNode(_ tableNode: ASTableNode, willDisplayRowWith node: ASCellNode) {
        if !node.isKind(of: ChatBaseNodeCell.self) {
            return
        }
        let _node = node as! ChatBaseNodeCell
        guard let indexPath = tableNode.indexPath(for: _node) else { return }
        // Here indexPath should always referer to updated data source.

        let presenter = self.presenterForIndexPath(indexPath)
        self.presentersByCell.setObject(presenter, forKey: _node)
        if self.updatesConfig.fastUpdates {
            self.visibleCells[indexPath] = _node
        }

        if self.isAdjustingInputContainer {
            UIView.performWithoutAnimation({
                // See https://github.com/badoo/Chatto/issues/133
                presenter.cellWillBeShown(_node)
            })
        } else {
            presenter.cellWillBeShown(_node)
        }
    }

    @objc(collectionView:shouldShowMenuForItemAtIndexPath:)
    open func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath?) -> Bool {
        // Note: IndexPath set optional due to https://github.com/badoo/Chatto/issues/310
        // Might be related: https://bugs.swift.org/browse/SR-2417
        guard let indexPath = indexPath else { return false }
        return self.presenterForIndexPath(indexPath).shouldShowMenu()
    }

    @objc(collectionView:canPerformAction:forItemAtIndexPath:withSender:)
    open func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath?, withSender sender: Any?) -> Bool {
        // Note: IndexPath set optional due to https://github.com/badoo/Chatto/issues/247. SR-2417 might be related
        // Might be related: https://bugs.swift.org/browse/SR-2417
        guard let indexPath = indexPath else { return false }
        return self.presenterForIndexPath(indexPath).canPerformMenuControllerAction(action)
    }

    @objc(collectionView:performAction:forItemAtIndexPath:withSender:)
    open func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        self.presenterForIndexPath(indexPath).performMenuControllerAction(action)
    }

    open func presenterForIndexPath(_ indexPath: IndexPath) -> ChatItemPresenterProtocol {
        return self.presenterForIndex(indexPath.item, chatItemCompanionCollection: self.chatItemCompanionCollection)
    }

    func presenterForIndex(_ index: Int, chatItemCompanionCollection items: ChatItemCompanionCollection) -> ChatItemPresenterProtocol {
        guard index < items.count else {
            // This can happen from didEndDisplayingCell if we reloaded with less messages
            return DummyChatItemPresenter()
        }
        return items[index].presenter
    }

    public func createPresenterForChatItem(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        return self.presenterFactory.createChatItemPresenter(chatItem)
    }

    public func decorationAttributesForIndexPath(_ indexPath: IndexPath) -> ChatItemDecorationAttributesProtocol? {
        return self.chatItemCompanionCollection[indexPath.item].decorationAttributes
    }
}
