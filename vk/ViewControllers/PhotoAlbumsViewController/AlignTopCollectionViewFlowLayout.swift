//
//  AlignBottomCollectionViewFlowLayout.swift
//  vk
//
//  Created by Jasf on 30.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

import UIKit

@objcMembers class AlignTopCollectionViewFlowLayout: UICollectionViewFlowLayout {
    var numberOfColumns: Int = 1
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attrs = super.layoutAttributesForElements(in: rect)
        var attrsCopy = [UICollectionViewLayoutAttributes]()
        var index: Int = 0
        let attrsCount = attrs!.count
        for  element in attrs! {
            let row = index / numberOfColumns
            var i=row * numberOfColumns
            var top = i + numberOfColumns
            if top > attrsCount {
                top = attrsCount
            }
            var maximumHeight: CGFloat = 0.0
            while (i<top) {
                let attr = attrs![i]
                if maximumHeight < attr.size.height {
                    maximumHeight = attr.size.height
                }
                i = i + 1
            }
            let elementCopy = element.copy() as! UICollectionViewLayoutAttributes
            if (elementCopy.representedElementCategory == .cell) {
                //NSLog("element \(index) Copy is : \(elementCopy.frame) but row: \(row) max: \(maximumHeight)")
                let delta = (maximumHeight - elementCopy.size.height) / 2
                elementCopy.frame.origin.y = elementCopy.frame.origin.y - delta
                //NSLog("delta for row: \(row) is \(delta)")
                //elementCopy.frame.origin.y = elementCopy.frame.origin.y * 2.0
            }
            index = index + 1
            
            attrsCopy.append(elementCopy)
        }
        
        return attrsCopy
    }
}
