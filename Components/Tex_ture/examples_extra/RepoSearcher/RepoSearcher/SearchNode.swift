//
//  SearchNode.swift
//  RepoSearcher
//
//  Created by Marvin Nazari on 2017-02-18.
//  Copyright © 2017 Marvin Nazari. All rights reserved.
//

import Foundation
import Async_DisplayKit

class SearchNode: A_SCellNode {
    var searchBarNode: SearchBarNode
    
    init(delegate: UISearchBarDelegate?) {
        self.searchBarNode = SearchBarNode(delegate: delegate)
        super.init()
        automaticallyManagesSubnodes = true
    }
    
    override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
        return A_SInsetLayoutSpec(insets: .zero, child: searchBarNode)
    }
}

final class SearchBarNode: A_SDisplayNode {
    
    weak var delegate: UISearchBarDelegate?
    
    init(delegate: UISearchBarDelegate?) {
        self.delegate = delegate
        super.init(viewBlock: {
            UISearchBar()
        }, didLoad: nil)
        style.preferredSize = CGSize(width: UIScreen.main.bounds.width, height: 44)
    }
    
    var searchBar: UISearchBar {
        return view as! UISearchBar
    }
    
    override func didLoad() {
        super.didLoad()
        searchBar.delegate = delegate
        searchBar.searchBarStyle = .minimal
        searchBar.tintColor = .black
        searchBar.backgroundColor = .white
        searchBar.placeholder = "Search"
    }
}
