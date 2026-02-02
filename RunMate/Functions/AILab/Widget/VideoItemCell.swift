//
//  VideoItemCell.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/1/27.
//

import Kingfisher
import UIKit

class VideoItemCell: UICollectionViewCell {
    static let identifier = "VideoItemCell"
    
    // 1. 定义 UI 组件
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private let textBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        return view
    }()
    
    private let promptLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.numberOfLines = 2
        label.textAlignment = .left
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .white
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // 2. 初始化
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.layer.cornerRadius = 24
        contentView.layer.masksToBounds = true
        
        // 层级结构
        contentView.addSubview(imageView)
        contentView.addSubview(textBackgroundView)
        textBackgroundView.addSubview(promptLabel)
        imageView.addSubview(loadingIndicator)
        
        // Auto Layout 约束 (保持不变)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        textBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            
            textBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            textBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            textBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            promptLabel.topAnchor.constraint(equalTo: textBackgroundView.topAnchor, constant: 6),
            promptLabel.leadingAnchor.constraint(equalTo: textBackgroundView.leadingAnchor, constant: 10),
            promptLabel.trailingAnchor.constraint(equalTo: textBackgroundView.trailingAnchor, constant: -10),
            promptLabel.bottomAnchor.constraint(equalTo: textBackgroundView.bottomAnchor, constant: -6)
        ])
    }
    
    // 3. 配置数据
    func configure(with item: PollinationFeedItem) {
        promptLabel.text = item.prompt ?? "No Prompt"
        
        guard let url = URL(string: item.imageURL) else { return }
        
        let processor = DownsamplingImageProcessor(size: self.bounds.size)
        
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
        
        // 使用 Kingfisher 设置占位图
        imageView.kf.setImage(
            with: url,
            placeholder: UIImage(named: "img_loading"),
            options: [
                .processor(processor),
                .scaleFactor(UIScreen.main.scale),
                .transition(.fade(0.25)),
                .cacheSerializer(DefaultCacheSerializer.default)
            ]
        ) { [weak self] _ in
            self?.loadingIndicator.stopAnimating()
            self?.loadingIndicator.isHidden = true
        }
    }
    
    // 4. 重置 Cell
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        promptLabel.text = nil
    }
}
