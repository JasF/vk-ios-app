//
//  ProductViewController.swift
//  Shop
//
//  Created by Dimitri on 10/11/2016.
//  Copyright © 2016 Dimitri. All rights reserved.
//

import UIKit

class ProductViewController: A_SViewController<A_STableNode> {

    // MARK: - Variables
    
    let product: Product
    
    private var tableNode: A_STableNode {
        return node
    }
    
    // MARK: - Object life cycle
    
    init(product: Product) {
        self.product = product
        super.init(node: A_STableNode())
        tableNode.delegate = self
        tableNode.dataSource = self
        tableNode.backgroundColor = UIColor.primaryBackgroundColor()
        tableNode.view.separatorStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTitle()
    }

}

extension ProductViewController: A_STableDataSource, A_STableDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: A_STableView, nodeForRowAt indexPath: IndexPath) -> A_SCellNode {
        let node = ProductCellNode(product: self.product)
        return node
    }
    
}

extension ProductViewController {
    func setupTitle() {
        self.title = self.product.title
    }
}
