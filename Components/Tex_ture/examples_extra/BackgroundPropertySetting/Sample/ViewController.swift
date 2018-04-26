//
//  ViewController.swift
//  Sample
//
//  Created by Adlai Holler on 2/17/16.
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//
//  THE SOFTWARE IS PROVIDED "A_S IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit
import Async_DisplayKit

final class ViewController: A_SViewController, A_SCollectionDelegate, A_SCollectionDataSource {
	let itemCount = 1000

	let itemSize: CGSize
	let padding: CGFloat
	var collectionNode: A_SCollectionNode {
		return node as! A_SCollectionNode
	}

	init() {
		let layout = UICollectionViewFlowLayout()
		(padding, itemSize) = ViewController.computeLayoutSizesForMainScreen()
		layout.minimumInteritemSpacing = padding
		layout.minimumLineSpacing = padding
		super.init(node: A_SCollectionNode(collectionViewLayout: layout))
		navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Color", style: .Plain, target: self, action: #selector(didTapColorsButton))
		navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Layout", style: .Plain, target: self, action: #selector(didTapLayoutButton))
		collectionNode.delegate = self
		collectionNode.dataSource = self
		title = "Background Updating"
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}

	// MARK: A_SCollectionDataSource

	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return itemCount
	}

	func collectionView(collectionView: A_SCollectionView, nodeBlockForItemAtIndexPath indexPath: NSIndexPath) -> A_SCellNodeBlock {
		return {
			let node = DemoCellNode()
			node.backgroundColor = UIColor.random()
			node.childA.backgroundColor = UIColor.random()
			node.childB.backgroundColor = UIColor.random()
			return node
		}
	}

	func collectionView(collectionView: A_SCollectionView, constrainedSizeForNodeAtIndexPath indexPath: NSIndexPath) -> A_SSizeRange {
		return A_SSizeRangeMake(itemSize, itemSize)
	}

	// MARK: Action Handling

	@objc private func didTapColorsButton() {
		let currentlyVisibleNodes = collectionNode.view.visibleNodes()
		let queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
		dispatch_async(queue) {
			for case let node as DemoCellNode in currentlyVisibleNodes {
				node.backgroundColor = UIColor.random()
			}
		}
	}

	@objc private func didTapLayoutButton() {
		let currentlyVisibleNodes = collectionNode.view.visibleNodes()
		let queue = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
		dispatch_async(queue) {
			for case let node as DemoCellNode in currentlyVisibleNodes {
				node.state.advance()
				node.setNeedsLayout()
			}
		}
	}

	// MARK: Static

	static func computeLayoutSizesForMainScreen() -> (padding: CGFloat, itemSize: CGSize) {
		let numberOfColumns = 4
		let screen = UIScreen.mainScreen()
		let scale = screen.scale
		let screenWidth = Int(screen.bounds.width * screen.scale)
		let itemWidthPx = (screenWidth - (numberOfColumns - 1)) / numberOfColumns
		let leftover = screenWidth - itemWidthPx * numberOfColumns
		let paddingPx = leftover / (numberOfColumns - 1)
		let itemDimension = CGFloat(itemWidthPx) / scale
		let padding = CGFloat(paddingPx) / scale
		return (padding: padding, itemSize: CGSize(width: itemDimension, height: itemDimension))
	}
}
