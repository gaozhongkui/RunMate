//
//  AIImageGridView.swift
//  RunMate
//

import SwiftUI
import UIKit

// MARK: - UIKit Collection View

final class AIImageGridViewController: UIViewController {

    var records: [AIGeneratedImage] = []
    var store: AIImageStore = .shared
    var onTap: ((AIGeneratedImage) -> Void)?

    private var collectionView: UICollectionView!
    private let spacing: CGFloat = 10
    private let horizontalPadding: CGFloat = 16

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupCollectionView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
        (collectionView.collectionViewLayout as? UICollectionViewFlowLayout).map { layout in
            layout.itemSize = cellSize(for: view.bounds.width)
        }
    }

    private func cellSize(for containerWidth: CGFloat) -> CGSize {
        let usableWidth = containerWidth - horizontalPadding * 2
        let columns = max(2, Int(containerWidth / 180))
        let side = (usableWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        return CGSize(width: side, height: side)
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        layout.sectionInset = UIEdgeInsets(
            top: 0,
            left: horizontalPadding,
            bottom: horizontalPadding,
            right: horizontalPadding
        )

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = false   // outer ScrollView handles scrolling
        collectionView.register(AIImageCell.self, forCellWithReuseIdentifier: AIImageCell.reuseID)
        view.addSubview(collectionView)
    }

    func reload(records: [AIGeneratedImage]) {
        self.records = records
        collectionView?.reloadData()
        view.setNeedsLayout()
    }

    // Compute total height for the given container width
    func preferredHeight(for width: CGFloat) -> CGFloat {
        let size = cellSize(for: width)
        let columns = max(2, Int(width / 180))
        let rows = Int(ceil(Double(records.count) / Double(columns)))
        let totalSpacing = spacing * CGFloat(max(0, rows - 1))
        return size.height * CGFloat(rows) + totalSpacing + horizontalPadding
    }
}

extension AIImageGridViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        records.count
    }

    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: AIImageCell.reuseID, for: indexPath) as! AIImageCell
        let record = records[indexPath.item]
        cell.configure(record: record, store: store)
        return cell
    }

    func collectionView(_ cv: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onTap?(records[indexPath.item])
    }
}

// MARK: - Cell

final class AIImageCell: UICollectionViewCell {
    static let reuseID = "AIImageCell"

    private let imageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    private let placeholderIcon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 12

        // Border
        contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        contentView.layer.borderWidth = 1

        // Shadow on the cell itself
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.masksToBounds = false

        // Image
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor(red: 0.118, green: 0.082, blue: 0.306, alpha: 1)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        // Placeholder sparkle icon
        placeholderIcon.image = UIImage(systemName: "sparkles")
        placeholderIcon.tintColor = UIColor.white.withAlphaComponent(0.2)
        placeholderIcon.contentMode = .scaleAspectFit
        placeholderIcon.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(placeholderIcon)
        NSLayoutConstraint.activate([
            placeholderIcon.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            placeholderIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            placeholderIcon.widthAnchor.constraint(equalToConstant: 32),
            placeholderIcon.heightAnchor.constraint(equalToConstant: 32),
        ])

        // Bottom gradient
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.78).cgColor]
        gradientLayer.locations = [0, 1]
        contentView.layer.addSublayer(gradientLayer)

        // Labels
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        dateLabel.font = UIFont.systemFont(ofSize: 10)
        dateLabel.textColor = UIColor.white.withAlphaComponent(0.55)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        stack.axis = .vertical
        stack.spacing = 3
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = CGRect(
            x: 0,
            y: contentView.bounds.height * 0.5,
            width: contentView.bounds.width,
            height: contentView.bounds.height * 0.5
        )
    }

    func configure(record: AIGeneratedImage, store: AIImageStore) {
        let img = store.loadImage(for: record)
        if let img {
            imageView.image = img
            placeholderIcon.isHidden = true
        } else {
            imageView.image = nil
            placeholderIcon.isHidden = false
        }
        titleLabel.text = record.styleTitle
        let formatter = DateFormatter()
        formatter.dateFormat = "d, MMM yyyy"
        dateLabel.text = formatter.string(from: record.createdAt)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        placeholderIcon.isHidden = false
    }
}

// MARK: - SwiftUI Wrapper

struct AIImageGridView: UIViewControllerRepresentable {
    let records: [AIGeneratedImage]
    let store: AIImageStore
    var onTap: (AIGeneratedImage) -> Void

    func makeUIViewController(context: Context) -> AIImageGridViewController {
        let vc = AIImageGridViewController()
        vc.store = store
        vc.onTap = onTap
        return vc
    }

    func updateUIViewController(_ vc: AIImageGridViewController, context: Context) {
        vc.onTap = onTap
        vc.reload(records: records)
    }
}

// MARK: - Self-sizing wrapper so SwiftUI ScrollView gets correct height

struct SelfSizingAIImageGrid: View {
    let records: [AIGeneratedImage]
    let store: AIImageStore
    var onTap: (AIGeneratedImage) -> Void

    @State private var gridHeight: CGFloat = 300

    var body: some View {
        GeometryReader { geo in
            AIImageGridView(records: records, store: store, onTap: onTap)
                .onAppear { updateHeight(width: geo.size.width) }
                .onChange(of: records.count) { _ in updateHeight(width: geo.size.width) }
                .onChange(of: geo.size.width) { w in updateHeight(width: w) }
        }
        .frame(height: gridHeight)
    }

    private func updateHeight(width: CGFloat) {
        let spacing: CGFloat = 10
        let horizontalPadding: CGFloat = 16
        let usableWidth = width - horizontalPadding * 2
        let columns = max(2, Int(width / 180))
        let side = (usableWidth - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        let rows = Int(ceil(Double(records.count) / Double(columns)))
        let totalSpacing = spacing * CGFloat(max(0, rows - 1))
        gridHeight = side * CGFloat(rows) + totalSpacing + horizontalPadding
    }
}
