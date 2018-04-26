//
//  PhotoTableNodeCell.swift
//  A_SDKgram-Swift
//
//  Created by Calum Harris on 09/01/2017.
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
//   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.//

import Foundation
import Async_DisplayKit

class PhotoTableNodeCell: A_SCellNode {
	
	let usernameLabel = A_STextNode()
	let timeIntervalLabel = A_STextNode()
	let photoLikesLabel = A_STextNode()
	let photoDescriptionLabel = A_STextNode()
	
	let avatarImageNode: A_SNetworkImageNode = {
		let imageNode = A_SNetworkImageNode()
		imageNode.contentMode = .scaleAspectFill
		imageNode.imageModificationBlock = A_SImageNodeRoundBorderModificationBlock(0, nil)
		return imageNode
	}()
	
	let photoImageNode: A_SNetworkImageNode = {
		let imageNode = A_SNetworkImageNode()
		imageNode.contentMode = .scaleAspectFill
		return imageNode
	}()
	
	init(photoModel: PhotoModel) {
		super.init()
		self.photoImageNode.url = URL(string: photoModel.url)
		self.avatarImageNode.url = URL(string: photoModel.ownerPicURL)
		self.usernameLabel.attributedText = photoModel.attrStringForUserName(withSize: Constants.CellLayout.FontSize)
		self.timeIntervalLabel.attributedText = photoModel.attrStringForTimeSinceString(withSize: Constants.CellLayout.FontSize)
		self.photoLikesLabel.attributedText = photoModel.attrStringLikes(withSize: Constants.CellLayout.FontSize)
		self.photoDescriptionLabel.attributedText = photoModel.attrStringForDescription(withSize: Constants.CellLayout.FontSize)
		self.automaticallyManagesSubnodes = true
	}
	
	override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
		
		// Header Stack
		
		var headerChildren: [A_SLayoutElement] = []
		
		let headerStack = A_SStackLayoutSpec.horizontal()
		headerStack.alignItems = .center
		avatarImageNode.style.preferredSize = CGSize(width: Constants.CellLayout.UserImageHeight, height: Constants.CellLayout.UserImageHeight)
		headerChildren.append(A_SInsetLayoutSpec(insets: Constants.CellLayout.InsetForAvatar, child: avatarImageNode))
		usernameLabel.style.flexShrink = 1.0
		headerChildren.append(usernameLabel)
		
		let spacer = A_SLayoutSpec()
		spacer.style.flexGrow = 1.0
		headerChildren.append(spacer)
		
		timeIntervalLabel.style.spacingBefore = Constants.CellLayout.HorizontalBuffer
		headerChildren.append(timeIntervalLabel)
		
		let footerStack = A_SStackLayoutSpec.vertical()
		footerStack.spacing = Constants.CellLayout.VerticalBuffer
		footerStack.children = [photoLikesLabel, photoDescriptionLabel]
		headerStack.children = headerChildren
		
		let verticalStack = A_SStackLayoutSpec.vertical()
		
		verticalStack.children = [A_SInsetLayoutSpec(insets: Constants.CellLayout.InsetForHeader, child: headerStack), A_SRatioLayoutSpec(ratio: 1.0, child: photoImageNode), A_SInsetLayoutSpec(insets: Constants.CellLayout.InsetForFooter, child: footerStack)]
		
		return verticalStack
	}
}
