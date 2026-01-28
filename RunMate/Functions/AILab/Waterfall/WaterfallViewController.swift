//
//  WaterfallViewController.swift
//  UITest
//
//  Created by gaozhongkui on 2025/12/24.
//

import UIKit

class WaterfallViewController: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    WaterfallLayoutDelegate
{
    private let observer = PollinationFeedObserver()
    private var collectionView: UICollectionView!
    private var dataList: [PollinationFeedItem] = []

    // MARK: - Header Constants

    private let maxHeight: CGFloat = 56
    private let minHeight: CGFloat = 44
    private var headerHeightConstraint: NSLayoutConstraint!

    // MARK: - Header Views

    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemUltraThinMaterial)
        return UIVisualEffectView(effect: blur)
    }()

    /// 内容容器（从 SafeArea 开始）
    private let headerContentView = UIView()

    private let searchBar: UIView = {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 15
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.15
        container.layer.shadowRadius = 4
        container.layer.shadowOffset = CGSize(width: 0, height: 2)

        let iconView = UIImageView(image: UIImage(systemName: "wand.and.stars"))
        iconView.tintColor = .secondaryLabel

        let label = UILabel()
        label.text = "Describe what you want the AI to create..."
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel

        let spacer = UIView()

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

    // MARK: - Loading

    private let loadingView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView(style: .large)
        v.hidesWhenStopped = true
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupCollectionView()
        setupHeaderView()
        setupLoadingView()

        loadingView.startAnimating()

        observer.onDataUpdate = { [weak self] items in
            guard let self else { return }
            self.dataList = items
            self.collectionView.reloadData()
            self.loadingView.stopAnimating()
        }

        observer.startListening()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let safeTop = view.safeAreaInsets.top
        collectionView.contentInset.top = maxHeight + safeTop
        collectionView.verticalScrollIndicatorInsets.top = maxHeight + safeTop
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        observer.stopListening()
    }

    // MARK: - Setup

    private func setupCollectionView() {
        let layout = WaterfallLayout()
        layout.delegate = self

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(VideoItemCell.self,
                                forCellWithReuseIdentifier: VideoItemCell.identifier)

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
        view.addSubview(blurView)
        view.addSubview(headerContentView)
        headerContentView.addSubview(searchBar)

        blurView.translatesAutoresizingMaskIntoConstraints = false
        headerContentView.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        headerHeightConstraint = headerContentView.heightAnchor.constraint(equalToConstant: maxHeight)

        NSLayoutConstraint.activate([
            // Blur：覆盖状态栏
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: headerContentView.bottomAnchor),

            // 内容区：SafeArea 内
            headerContentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerHeightConstraint,

            // SearchBar
            searchBar.leadingAnchor.constraint(equalTo: headerContentView.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: headerContentView.trailingAnchor, constant: -16),
            searchBar.bottomAnchor.constraint(equalTo: headerContentView.bottomAnchor, constant: -10),
            searchBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupLoadingView() {
        view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Scroll

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let safeTop = view.safeAreaInsets.top
        // 计算当前的实际偏移量（考虑了初始的 contentInset）
        let offset = scrollView.contentOffset.y + maxHeight + safeTop

        // 动态计算目标高度
        // 当向上滚动时（offset > 0），高度减小；向下拖拽时（offset < 0），高度增加
        let targetHeight = maxHeight - offset
        
        // 限制在 [minHeight, maxHeight] 之间，除非你想做下拉放大效果
        if targetHeight >= maxHeight {
            headerHeightConstraint.constant = targetHeight // 下拉放大
        } else if targetHeight <= minHeight {
            headerHeightConstraint.constant = minHeight // 最小收缩高度
        } else {
            headerHeightConstraint.constant = targetHeight // 中间过渡
        }
    }

    // MARK: - DataSource

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int
    {
        dataList.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoItemCell.identifier,
            for: indexPath
        ) as! VideoItemCell
        cell.configure(with: dataList[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        heightForItemAt indexPath: IndexPath,
                        itemWidth: CGFloat) -> CGFloat
    {
        let item = dataList[indexPath.item]
        let w = CGFloat(item.width ?? 0)
        let h = CGFloat(item.height ?? 0)
        guard w > 0 else { return itemWidth }
        return itemWidth * max(h / w, 1.0)
    }
}
