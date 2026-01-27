//
//  WaterfallViewController.swift
//  UITest
//
//  Created by gaozhongkui on 2025/12/24.
//

import UIKit

class WaterfallViewController: UIViewController, UICollectionViewDataSource, WaterfallLayoutDelegate {
    private let observer = PollinationFeedObserver()
    private var collectionView: UICollectionView!
    var dataList: [PollinationFeedItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let layout = WaterfallLayout()
        layout.delegate = self

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .white
        collectionView.dataSource = self

        collectionView.register(VideoItemCell.self, forCellWithReuseIdentifier: VideoItemCell.identifier)

        view.addSubview(collectionView)

        observer.onDataUpdate = { [weak self] items in
            self?.dataList = items
            self?.collectionView.reloadData()
        }
        observer.startListening()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        observer.stopListening()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // 使用自定义 Cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoItemCell.identifier, for: indexPath) as! VideoItemCell
        cell.configure(with: dataList[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath, itemWidth: CGFloat) -> CGFloat {
        let item = dataList[indexPath.item]
        let originalWidth = CGFloat(item.width ?? 0)
        let originalHeight = CGFloat(item.height ?? 0)

        guard originalWidth > 0 else { return 200 }

        // 比例 = 原始高 / 原始宽
        let ratio = originalHeight / originalWidth
        // 目标高度 = 当前列宽 * 比例
        return itemWidth * ratio
    }
}
