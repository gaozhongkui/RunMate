//
//  WaterfallLayout.swift
//  UITest
//
//  Created by gaozhongkui on 2025/12/24.
//

import UIKit

class WaterfallLayout: UICollectionViewLayout {
    weak var delegate: WaterfallLayoutDelegate?

    var columnCount: Int = 2
    var columnSpacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    var sectionInset: UIEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)

    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0

    private var contentWidth: CGFloat {
        guard let cv = collectionView else {
            return 0
        }
        return cv.bounds.width - sectionInset.left - sectionInset.right
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: contentWidth, height: contentHeight)
    }

    override func prepare() {
        guard let collectionView = collectionView else { return }
        cache.removeAll()
        contentHeight = 0

        let columnWidth = (contentWidth - CGFloat(columnCount - 1) * columnSpacing) / CGFloat(columnCount)
        var columnHeights = Array(repeating: sectionInset.top, count: columnCount)

        for item in 0 ..< collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)

            // 找到当前最短列
            let minColumn = columnHeights.firstIndex(of: columnHeights.min()!)!
            let x = sectionInset.left + CGFloat(minColumn) * (columnWidth + columnSpacing)
            let y = columnHeights[minColumn]

            let height = delegate?.collectionView(collectionView, heightForItemAt: indexPath, itemWidth: columnWidth) ?? 100
            let frame = CGRect(x: x, y: y, width: columnWidth, height: height)

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            cache.append(attributes)

            columnHeights[minColumn] = frame.maxY + rowSpacing
            contentHeight = max(contentHeight, frame.maxY)
        }

        contentHeight += sectionInset.bottom
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        cache.filter { $0.frame.intersects(rect)
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        cache.first { $0.indexPath == indexPath }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
