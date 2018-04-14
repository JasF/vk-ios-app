//
//  SearchViewController.swift
//  RepoSearcher
//
//  Created by Marvin Nazari on 2017-02-18.
//  Copyright © 2017 Marvin Nazari. All rights reserved.
//

import UIKit
import Async_DisplayKit
import IGListKit

class SearchToken: NSObject {}

final class SearchViewController: A_SViewController<A_SCollectionNode> {
    
    lazy var adapter: IGListAdapter = {
        return IGListAdapter(updater: IGListAdapterUpdater(), viewController: self, workingRangeSize: 0)
    }()
    
    let words = ["first", "second", "third", "more", "hi", "others"]
    
    let searchToken = SearchToken()
    var filterString = ""
    
    init() {
        let flowLayout = UICollectionViewFlowLayout()
        super.init(node: A_SCollectionNode(collectionViewLayout: flowLayout))
        adapter.setA_SDKCollectionNode(node)
        adapter.dataSource = self
        title = "Search"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchViewController: IGListAdapterDataSource {
    func listAdapter(_ listAdapter: IGListAdapter, sectionControllerFor object: Any) -> IGListSectionController {
        if object is SearchToken {
            let section = SearchSectionController()
            section.delegate = self
            return section
        }
        return LabelSectionController()
    }
    
    func emptyView(for listAdapter: IGListAdapter) -> UIView? {
        // emptyView dosent work in this secenario, there is always one section (searchbar) present in collection
        return nil
    }
    
    func objects(for listAdapter: IGListAdapter) -> [IGListDiffable] {
        guard filterString != "" else { return [searchToken] + words.map { $0 as IGListDiffable } }
        return [searchToken] + words.filter { $0.lowercased().contains(filterString.lowercased()) }.map { $0 as IGListDiffable }
    }
}

extension SearchViewController: SearchSectionControllerDelegate {
    func searchSectionController(_ sectionController: SearchSectionController, didChangeText text: String) {
        filterString = text
        adapter.performUpdates(animated: true, completion: nil)
    }
}
