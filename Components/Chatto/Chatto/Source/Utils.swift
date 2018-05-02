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
import UIKit
import AsyncDisplayKit

private let scale = UIScreen.main.scale

infix operator >=~
func >=~ (lhs: CGFloat, rhs: CGFloat) -> Bool {
    return round(lhs * scale) >= round(rhs * scale)
}

@inline(__always)
public func bma_combine(hashes: [Int]) -> Int {
    return hashes.reduce(0, { 31 &* $0 &+ $1.hashValue })
}

extension UIScrollView {
    func chatto_setContentInsetAdjustment(enabled: Bool, in viewController: UIViewController) {
        #if swift(>=3.2)
            if #available(iOS 11.0, *) {
                self.contentInsetAdjustmentBehavior = enabled ? .always : .never
            } else {
                viewController.automaticallyAdjustsScrollViewInsets = enabled
            }
        #else
            viewController.automaticallyAdjustsScrollViewInsets = enabled
        #endif
    }
}

open class ChatBaseNodeCellInternal : ASCellNode {
    
    public let textNode = ASTextNode()
    public override init() {
        super.init()
        textNode.attributedText = NSAttributedString.init(string: String(describing: self))
        textNode.backgroundColor = UIColor.orange
        self.addSubnode(textNode)
    }
    override open func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec.init(insets: UIEdgeInsetsMake(10, 10, 10, 10), child: textNode)
    }
    
    public var window: UIWindow?
    
    public init(frame: CGRect) {
        super.init()
    }
    
    public init?(coder aDecoder: NSCoder) {
        super.init()
    }
    
    open func prepareForReuse() {
        
    }
    
    open func layoutSubviews() {
    }
    
    open func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: 0, height: 0)
    }
    
    open func addGestureRecognizer(_ gr: Any) {
        
    }
    
    open func addSubview(_ sb: Any) {
        
    }
    
    open func didMoveToWindow() {
        
    }
    
    open func addConstraint(_ c: Any) {
        
    }
}


open class ChatBaseNodeCell : ChatBaseNodeCellInternal {
    public var contentView = ChatBaseNodeCellInternal()
}
