//
//  WaterfallLayoutDelegate.swift
//  UITest
//
//  Created by gaozhongkui on 2025/12/24.
//

import UIKit

protocol WaterfallLayoutDelegate: AnyObject {
    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        itemWidth: CGFloat
    ) -> CGFloat

}
