//
//  LabelSectionController.swift
//  RepoSearcher
//
//  Created by Marvin Nazari on 2017-02-18.
//  Copyright © 2017 Marvin Nazari. All rights reserved.
//

import Foundation
import Async_DisplayKit
import IGListKit

final class LabelSectionController: IGListSectionController, IGListSectionType, A_SSectionController {
    var object: String?

    func nodeBlockForItem(at index: Int) -> A_SCellNodeBlock {
        let text = object ?? ""
        return {
            let node = A_STextCellNode()
            node.text = text
            return node
        }
    }
    
    func numberOfItems() -> Int {
        return 1
    }
    
    func didUpdate(to object: Any) {
        self.object = String(describing: object)
    }
    
    func didSelectItem(at index: Int) {}
    
    //A_SDK Replacement
    func sizeForItem(at index: Int) -> CGSize {
        return A_SIGListSectionControllerMethods.sizeForItem(at: index)
    }
    
    func cellForItem(at index: Int) -> UICollectionViewCell {
        return A_SIGListSectionControllerMethods.cellForItem(at: index, sectionController: self)
    }
}

