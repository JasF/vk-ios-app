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

class DummyNode : ASCellNode {
    let textNode = ASTextNode()
    public override init() {
        super.init()
        textNode.attributedText = NSAttributedString.init(string: "Dummy")
        self.addSubnode(textNode)
    }
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(10, 10, 10, 10), child: textNode)
    }
}
// Handles messages that aren't supported so they appear as invisible
class DummyChatItemPresenter: ChatItemPresenterProtocol {
    func getMessageModel() -> Any? {
        return nil
    }

    class func registerCells(_ collectionView: UICollectionView) {
        collectionView.register(DummyCollectionViewCell.self, forCellWithReuseIdentifier: "cell-id-unhandled-message")
    }

    var canCalculateHeightInBackground: Bool {
        return true
    }

    func heightForCell(maximumWidth width: CGFloat, decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        return 0
    }

    func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> ASCellNode {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "cell-id-unhandled-message", for: indexPath)
    }

    func configureCell(_ cell: ASCellNode, decorationAttributes: ChatItemDecorationAttributesProtocol?) {
        cell.isHidden = true
    }
    
    
    open func dequeueNode(tableNode: ASTableNode, indexPath: IndexPath) -> ASCellNode {
        let node = DummyNode.init()
        return node
    }
    
    open func configureNode(_ node: ASCellNode, decorationAttributes: ChatItemDecorationAttributesProtocol?) {
        
    }
}

class DummyCollectionViewCell: UICollectionViewCell {}
