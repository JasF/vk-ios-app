//
//  TypingPresenter.swift
//  vk
//
//  Created by Jasf on 21.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import Foundation
import UIKit


public class TypingPresenterBuilder: ChatItemPresenterBuilderProtocol {
    
    public func canHandleChatItem(_ chatItem: ChatItemProtocol) -> Bool {
        return chatItem is TypingModel
    }
    
    public func createPresenterWithChatItem(_ chatItem: ChatItemProtocol) -> ChatItemPresenterProtocol {
        assert(self.canHandleChatItem(chatItem))
        return TypingPresenter(typingModel: chatItem as! TypingModel)
    }
    
    public var presenterType: ChatItemPresenterProtocol.Type {
        return TypingPresenter.self
    }
}

class TypingPresenter: ChatItemPresenterProtocol {
    var nodeFactory: NodeFactory?
    
    func getMessageModel() -> Any? {
        return nil
    }
    
    
    let typingModel: TypingModel
    init (typingModel: TypingModel) {
        self.typingModel = typingModel
    }
    
    private static let cellReuseIdentifier = TypingCell.self.description()
    
    static func registerCells(_ collectionView: UICollectionView) {
        collectionView.register(TypingCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
    }
    
    func dequeueCell(collectionView: UICollectionView, indexPath: IndexPath) -> ChatBaseNodeCell {
        return TypingCell.init()// WallUserActionNode.init("typing", number: 0) //collectionView.dequeueReusableCell(withReuseIdentifier: TypingPresenter.cellReuseIdentifier, for: indexPath)
    }
    
    func configureCell(_ cell: ChatBaseNodeCell, decorationAttributes: ChatItemDecorationAttributesProtocol?) {
        guard let typingCell = cell as? TypingCell else {
            assert(false, "expecting status cell")
            return
        }
        
        //typingCell.text = "Typing Text"
    }
    
    var canCalculateHeightInBackground: Bool {
        return true
    }
    
    func heightForCell(maximumWidth width: CGFloat, decorationAttributes: ChatItemDecorationAttributesProtocol?) -> CGFloat {
        return 30;//TypingCell.imageSize().height
    }
}
