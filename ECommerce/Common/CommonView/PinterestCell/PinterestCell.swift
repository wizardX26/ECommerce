//
//  PinterestICell.swift
//  MyKiot
//
//  Created by Nguyen Duc Hung on 19/6/25.
//

import UIKit

class PinterestCell: UICollectionViewCell {

    @IBOutlet weak var viewInclude: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.clipsToBounds = true

        self.titleLabel.numberOfLines = 0
        self.titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.layer.cornerRadius = 4
        self.imageView.clipsToBounds = true
        
        self.viewInclude.layer.cornerRadius = 4
        self.viewInclude.layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.viewInclude.layer.shadowOpacity = 0.2
        self.viewInclude.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.viewInclude.layer.shadowRadius = 4
        self.viewInclude.layer.masksToBounds = false
        
    }

    func configure(with product: Product) {
        //
        self.titleLabel.text = product.name
        
//        let urlImage = URL(string: Constant.domain + "uploads/" + product.img)
//                KF.url(urlImage)
//                    .fade(duration: 0)
//                    .loadDiskFileSynchronously()
//                    .placeholder(UIImage(named: ""))
//                    .set(to: self.imageView)
    }
}

protocol PinterestLayoutDelegate: AnyObject {
    func collectionView(_ collectionView: UICollectionView, heightForItemAt indexPath: IndexPath) -> CGFloat
}

class PinterestLayout: UICollectionViewLayout {
    weak var delegate: PinterestLayoutDelegate?

    var numberOfColumns = 2
    var cellPadding: CGFloat = 4

    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0

    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let insets = collectionView.adjustedContentInset
        return collectionView.bounds.width - insets.left - insets.right
    }

    override var collectionViewContentSize: CGSize {
        return CGSize(width: self.contentWidth, height: self.contentHeight)
    }

    override func prepare() {
        guard self.cache.isEmpty, let collectionView = collectionView else { return }

        let columnWidth = self.contentWidth / CGFloat(self.numberOfColumns)
        var xOffset: [CGFloat] = (0..<self.numberOfColumns).map { CGFloat($0) * columnWidth }
        var yOffset: [CGFloat] = .init(repeating: 0, count: self.numberOfColumns)

        var column = 0

        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: item, section: 0)

            let itemHeight = self.delegate?.collectionView(collectionView, heightForItemAt: indexPath) ?? 180
            let height = itemHeight + self.cellPadding * 2
            let frame = CGRect(x: xOffset[column], y: yOffset[column], width: columnWidth, height: height)
            let insetFrame = frame.insetBy(dx: self.cellPadding, dy: self.cellPadding)

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = insetFrame
            self.cache.append(attributes)

            
            self.contentHeight = max(self.contentHeight, frame.maxY)
            yOffset[column] = yOffset[column] + height
            

            column = yOffset.firstIndex(of: yOffset.min() ?? 0) ?? 0
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.cache.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return self.cache.first { $0.indexPath == indexPath }
    }

//    override func invalidateLayout() {
//        super.invalidateLayout()
//        self.cache.removeAll()
//        self.contentHeight = 0
//    }
}
