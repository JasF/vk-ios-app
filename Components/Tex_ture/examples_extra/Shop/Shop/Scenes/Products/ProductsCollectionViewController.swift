//
//  ProductsCollectionViewController.swift
//  Shop
//
//  Created by Dimitri on 15/11/2016.
//  Copyright © 2016 Dimitri. All rights reserved.
//

import UIKit

class ProductsCollectionViewController: A_SViewController<A_SCollectionNode> {

    // MARK: - Variables
    
    var products: [Product]
    
    private var collectionNode: A_SCollectionNode {
        return node
    }
    
    // MARK: - Object life cycle
    
    init(products: [Product]) {
        self.products = products
        super.init(node: A_SCollectionNode(collectionViewLayout: ProductsLayout()))
        collectionNode.delegate = self
        collectionNode.dataSource = self
        collectionNode.backgroundColor = UIColor.primaryBackgroundColor()
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

extension ProductsCollectionViewController: A_SCollectionDataSource, A_SCollectionDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.products.count
    }
    
    func collectionView(_ collectionView: A_SCollectionView, nodeForItemAt indexPath: IndexPath) -> A_SCellNode {
        let product = self.products[indexPath.row]
        return ProductCollectionNode(product: product)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = self.products[indexPath.row]
        let viewController = ProductViewController(product: product)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
}

extension ProductsCollectionViewController {
    
    func setupTitle() {
        self.title = "Bears"
    }
    
}
