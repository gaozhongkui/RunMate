//
//  WaterfallViewController.swift
//  UITest
//
//  Created by gaozhongkui on 2025/12/24.
//

import DotLottie
import UIKit

class WaterfallViewController: UIViewController,
    UICollectionViewDataSource,
    UICollectionViewDelegate,
    WaterfallLayoutDelegate
{
    private let observer = PollinationFeedObserver()
    private var collectionView: UICollectionView!
    private var dataList: [PollinationFeedItem] = []

    private let maxHeight: CGFloat = 56
    private let minHeight: CGFloat = 44
    private var headerHeightConstraint: NSLayoutConstraint!

    var onHeaderTap: (() -> Void)?

    var onItemTap: ((PollinationFeedItem) -> Void)?

    private let headerContentView = UIView()

    private let searchBar: UIView = {
        let container = GradientBorderView()

        // 设置渐变色 (青色 -> 紫粉色)
        container.gradientColors = [
            UIColor(red: 0/255, green: 255/255, blue: 255/255, alpha: 1.0),
            UIColor(red: 255/255, green: 0/255, blue: 255/255, alpha: 1.0)
        ]

        // 2. 更新图标为放大镜
        let iconView = UIImageView(image: UIImage(systemName: "wand.and.stars"))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])

        // 3. 更新文字内容和颜色
        let label = UILabel()
        label.text = "Explore AI Art..."
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .white

        let spacer = UIView()

        let stack = UIStackView(arrangedSubviews: [iconView, label, spacer])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 12

        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        return container
    }()

    @objc private func headerTap() {
        print("gzk  点击头部")
        onHeaderTap?()
    }

    private let loadingView: DotLottieAnimationView = {
        let config = AnimationConfig(autoplay: true, loop: true)
        let lottieView = DotLottieAnimationView(dotLottieViewModel: DotLottieAnimation(fileName: "loading", config: config))
        return lottieView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "#0A0A0F")

        setupCollectionView()
        setupHeaderView()
        setupLoadingView()

        loadingView.dotLottieViewModel.play()

        observer.onDataUpdate = { [weak self] items in
            guard let self else { return }
            self.dataList = items
            self.collectionView.reloadData()
            self.loadingView.dotLottieViewModel.stop()
            self.loadingView.isHidden = true
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
        view.addSubview(headerContentView)
        headerContentView.addSubview(searchBar)

        headerContentView.translatesAutoresizingMaskIntoConstraints = false
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.isUserInteractionEnabled = true
        let searchTap = UITapGestureRecognizer(target: self, action: #selector(headerTap))
        searchBar.addGestureRecognizer(searchTap)

        headerHeightConstraint = headerContentView.heightAnchor.constraint(equalToConstant: maxHeight)

        NSLayoutConstraint.activate([
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
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 200),
            loadingView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

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
        return itemWidth * max(h/w, 1.0)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedItem = dataList[indexPath.item]
        onItemTap?(selectedItem)
    }
}
