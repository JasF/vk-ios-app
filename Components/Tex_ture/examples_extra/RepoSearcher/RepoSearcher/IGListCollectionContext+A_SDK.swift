//
//  IGListCollectionContext+A_SDK.swift
//  RepoSearcher
//
//  Created by Marvin Nazari on 2017-02-18.
//  Copyright © 2017 Marvin Nazari. All rights reserved.
//

import Foundation
import IGListKit
import Async_DisplayKit

extension IGListCollectionContext {
    func nodeForItem(at index: Int, sectionController: IGListSectionController) -> A_SCellNode? {
        return (cellForItem(at: index, sectionController: sectionController) as? _A_SCollectionViewCell)?.node
    }
}
