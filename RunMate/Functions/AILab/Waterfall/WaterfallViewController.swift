//
//  WaterfallViewController.swift
//  UITest
//
//  Created by gaozhongkui on 2025/12/24.
//

import UIKit

class WaterfallViewController: UIViewController, UICollectionViewDataSource, WaterfallLayoutDelegate, UICollectionViewDelegate {
    private let observer = PollinationFeedObserver()
    private var collectionView: UICollectionView!
    private var dataList: [PollinationFeedItem] = []

    // Header 相关常量
    private let maxHeight: CGFloat = 80
    private let minHeight: CGFloat = 60
    private var headerHeightConstraint: NSLayoutConstraint!

    // 1. 定义 Header 视图
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        return view
    }()

    private let searchBar: UIView = {
        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 15

        // 阴影（等价 SwiftUI .shadow(radius: 2)）
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.15
        container.layer.shadowRadius = 2
        container.layer.shadowOffset = CGSize(width: 0, height: 2)

        // icon
        let iconView = UIImageView(image: UIImage(systemName: "wand.and.stars"))
        iconView.tintColor = .secondaryLabel
        iconView.contentMode = .scaleAspectFit
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        // placeholder text
        let label = UILabel()
        label.text = "Describe what you want the Al to create..."
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel

        // spacer
        let spacer = UIView()

        // stack
        let stack = UIStackView(arrangedSubviews: [iconView, label, spacer])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8

        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])

        return container
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupCollectionView()
        setupHeaderView()

        // 开启数据监听
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

    private func setupCollectionView() {
        let layout = WaterfallLayout()
        layout.delegate = self

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.contentInset = UIEdgeInsets(top: maxHeight, left: 0, bottom: 0, right: 0)
        collectionView.verticalScrollIndicatorInsets = UIEdgeInsets(top: maxHeight, left: 0, bottom: 0, right: 0)

        collectionView.register(VideoItemCell.self, forCellWithReuseIdentifier: VideoItemCell.identifier)

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupHeaderView() {
        view.addSubview(headerView)
        headerView.addSubview(searchBar)

        headerView.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        // 这里的约束是核心：我们通过修改这个高度约束来实现伸缩
        headerHeightConstraint = headerView.heightAnchor.constraint(equalToConstant: maxHeight)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerHeightConstraint,

            // 搜索框在 Header 内部水平居中，底部留一点 Padding
            searchBar.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            searchBar.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10),
            searchBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let yOffset = scrollView.contentOffset.y

        // yOffset 初始值是 -maxHeight (即 -80)
        // 向上滚动时，yOffset 会变大（例如变为 -50, 0, 100...）
        let currentHeight = -yOffset

        if currentHeight > maxHeight {
            // 向下拉时，Header 跟着变大（Stretching 效果）
            headerHeightConstraint.constant = currentHeight
        } else if currentHeight < minHeight {
            // 向上滑到极限时，保持最小高度
            headerHeightConstraint.constant = minHeight
        } else {
            // 在 min 和 max 之间自由缩放
            headerHeightConstraint.constant = currentHeight
        }

        // 动态调整搜索框透明度（可选，类似 SwiftUI 渐变效果）
        let progress = (currentHeight - minHeight) / (maxHeight - minHeight)
        searchBar.alpha = progress
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

    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        itemWidth: CGFloat
    ) -> CGFloat {
        let item = dataList[indexPath.item]
        let originalWidth = CGFloat(item.width ?? 0)
        let originalHeight = CGFloat(item.height ?? 0)

        guard originalWidth > 0 else { return itemWidth } // 至少 1:1

        // 原始比例
        let rawRatio = originalHeight / originalWidth

        // 最小比例限制为 1:1
        let ratio = max(rawRatio, 1.0)

        return itemWidth * ratio
    }
}
