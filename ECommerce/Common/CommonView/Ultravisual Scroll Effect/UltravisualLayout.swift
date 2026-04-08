/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

// The heights are declared as constants outside of the class so they can be easily referenced elsewhere 
struct UltravisualLayoutConstants {
  struct Cell {
    // The height of the image cell when collapsed (khi scroll xuống)
    // ✅ LƯU Ý: Giá trị này không còn được sử dụng trực tiếp
    // standardHeight giờ được tính động dựa trên collapseRatio
    static let standardHeight: CGFloat = 172
    // The height of the image cell when expanded (nửa chiều cao màn hình)
    // Sẽ được tính động dựa trên collectionView height
    
    // ✅ TUỲ CHỈNH: Tỉ lệ collapse của cell 0
    // Giá trị càng lớn thì gấp càng nhiều (cell 0 nhỏ hơn khi collapsed)
    // Ví dụ: 2.0 = gấp một nửa, 3.5 = gấp nhiều hơn
      static let collapseRatio: CGFloat = 2.2 // Có thể thay đổi thành 2.0, 3.0, 3.5, v.v.
  }
}

// MARK: Properties and Variables

class UltravisualLayout: UICollectionViewLayout {
  // The amount the user needs to scroll before the image cell collapses
  // Tính toán dựa trên sự chênh lệch giữa featuredHeight và standardHeight
  var dragOffset: CGFloat {
    guard let collectionView = collectionView else { return 0 }
    let h = collectionView.bounds.height
    let featured = h / 2
    let standard = featured / UltravisualLayoutConstants.Cell.collapseRatio
    return featured - standard
  }
  
  var cache: [UICollectionViewLayoutAttributes] = []
  
  // Biến lưu bottom của cell 0 để tính toán vị trí cell 1
  private var cell0Bottom: CGFloat = 0
  
  // Cache các giá trị tính toán để tránh tính lại nhiều lần
  private var cachedBounds: CGRect = .zero
  private var cachedContentSize: CGSize = .zero
  
  // Chiều cao thực tế của cell 1 (cell thông tin)
  // Ước tính dựa trên các components: ~650pt bao gồm padding
  private var infoCellHeight: CGFloat {
    // Ước tính chiều cao cell 1 dựa trên các components:
    // - Top padding: 12pt
    // - ProductInfoLabel: ~24pt
    // - Spacing: 12pt
    // - PriceView: 96pt
    // - Spacing: 16pt
    // - Description (5 lines): ~100pt
    // - Spacing: 16pt
    // - SoldInfo: ~20pt
    // - Spacing: 16pt
    // - Rating: ~20pt
    // - Spacing: 16pt
    // - GuaranteedCell: ~60pt
    // - Bottom padding: ~222pt (UIScreen.main.bounds.height / 3)
    // Tổng: ~650pt
    return 650
  }
  
  // Khoảng cách từ bottom màn hình đến nội dung cell 1 khi scroll
  // Đảm bảo nội dung luôn trong vùng nhìn thấy
  private let bottomPadding: CGFloat = 180
  
  // Cấu hình damping cho hiệu ứng scroll ngược lại
  // Giá trị càng lớn thì damping càng mạnh (scroll mượt hơn)
  private let dampingThreshold: CGFloat = 50 // Khoảng cách để bắt đầu damping
  private let dampingFactor: CGFloat = 0.3 // Hệ số damping (0.0 = không damping, 1.0 = damping tối đa)
  
  // Returns the item index of the currently featured cell 
  var featuredItemIndex: Int {
    // Với chỉ 2 cells, top cell (index 0) luôn là featured cell để có hiệu ứng scroll
    // Chỉ trả về 0 để đảm bảo top cell luôn có scroll effect
    return 0
  }
  
  // Returns a value between 0 and 1 that represents how close the next cell is to becoming the featured cell 
  var nextItemPercentageOffset: CGFloat {
    guard let collectionView = collectionView, dragOffset > 0 else { return 0 }
    let contentOffsetY = collectionView.contentOffset.y
    
    // Tính tỉ lệ collapse: 0 = expanded, 1 = collapsed
    // Khi contentOffsetY = 0: percentage = 0 (cell 0 ở full height)
    // Khi contentOffsetY = dragOffset: percentage = 1 (cell 0 đã collapsed)
    // Khi contentOffsetY > dragOffset: percentage = 1 (giữ collapsed)
    // Khi contentOffsetY < 0: percentage = 0 (overscroll, giữ expanded)
    
    if contentOffsetY <= 0 {
      return 0 // Ở đầu hoặc overscroll lên trên
    } else if contentOffsetY >= dragOffset {
      return 1 // Đã collapsed hoàn toàn
    } else {
      // Trong quá trình collapse: tính tỉ lệ từ 0 đến 1
      return contentOffsetY / dragOffset
    }
  }
  
  // Chiều cao của image cell khi expanded (nửa màn hình)
  var featuredHeight: CGFloat {
    guard let collectionView = collectionView else { return 0 }
    return collectionView.bounds.height / 2
  }
  
  // Chiều cao của image cell khi collapsed (tính theo collapseRatio)
  // collapseRatio có thể tuỳ chỉnh: 2.0 = gấp một nửa, 3.5 = gấp nhiều hơn
  var standardHeight: CGFloat {
    return featuredHeight / UltravisualLayoutConstants.Cell.collapseRatio
  }
  
  // Returns the width of the collection view 
  var width: CGFloat {
    return collectionView?.bounds.width ?? 0
  }
  
  // Returns the height of the collection view 
  var height: CGFloat {
    return collectionView?.bounds.height ?? 0
  }
  
  // Returns the number of items in the collection view 
  var numberOfItems: Int {
    return collectionView?.numberOfItems(inSection: 0) ?? 0
  }
}

// MARK: UICollectionViewLayout

extension UltravisualLayout {
  // Return the size of all the content in the collection view 
  override var collectionViewContentSize : CGSize {
    guard let collectionView = collectionView else {
      return cachedContentSize
    }
    
    let currentBounds = collectionView.bounds
    
    // Cache content size nếu bounds không thay đổi
    if currentBounds == cachedBounds && cachedContentSize != .zero {
      return cachedContentSize
    }
    
    let h = currentBounds.height
    let featured = h / 2 // Chiều cao cell 0 khi expanded
    let standard = featured / UltravisualLayoutConstants.Cell.collapseRatio // Chiều cao cell 0 khi collapsed
    let dragOffset = featured - standard
    
    // Tính toán content size để đảm bảo scroll mượt mà:
    // Content size cần đủ lớn để:
    // 1. Cho phép scroll từ 0 đến dragOffset (collapse cell 0) - khoảng dragOffset
    // 2. Sau khi collapse, cell 1 bắt đầu từ standardHeight
    // 3. Cell 1 có thể scroll để hiển thị đầy đủ nội dung với padding bottom
    
    // Tính toán vùng có thể nhìn thấy cho cell 1 sau khi collapse
    let visibleArea = h - standard - bottomPadding // Vùng có thể nhìn thấy cho cell 1
    
    // Nếu cell 1 dài hơn vùng nhìn thấy, cần scroll thêm
    let scrollableContent = max(0, infoCellHeight - visibleArea)
    
    // Content size = dragOffset (để collapse cell 0) + scrollableContent (để scroll cell 1)
    // Đảm bảo có thể scroll đủ để collapse cell 0 và xem toàn bộ cell 1
    let calculatedContentHeight = dragOffset + scrollableContent
    
    // Đảm bảo content size tối thiểu = featuredHeight + infoCellHeight
    // để có thể scroll từ đầu (cell 0 expanded) đến cuối (cell 1 đầy đủ) mượt mà
    let minContentHeight = featured + infoCellHeight
    let finalContentHeight = max(calculatedContentHeight, minContentHeight)
    
    cachedContentSize = CGSize(width: currentBounds.width, height: finalContentHeight)
    cachedBounds = currentBounds
    
    return cachedContentSize
  }
  
  override func prepare() {
    guard let collectionView = collectionView,
          collectionView.bounds.width > 0,
          collectionView.bounds.height > 0 else {
      cache.removeAll(keepingCapacity: false)
      return
    }
    
    // Tính toán các giá trị một lần để tái sử dụng
    let contentOffsetY = collectionView.contentOffset.y
    let currentDragOffset = dragOffset
    let currentWidth = width
    let currentStandardHeight = standardHeight
    let currentFeaturedHeight = featuredHeight
    let percentageOffset = nextItemPercentageOffset
    
    // Tối ưu: chỉ update cache khi số lượng items thay đổi hoặc cache chưa có
    if cache.count != numberOfItems {
      cache.removeAll(keepingCapacity: true)
    }
    
    // Tính toán frame cho cell 0 (cell ảnh)
    // Logic: Cell 0 luôn bắt đầu từ y = 0, chỉ thay đổi chiều cao khi scroll
    var cell0Frame: CGRect = .zero
    var cell0Y: CGFloat = 0
    var cell0Height: CGFloat = 0
    
    // Đảm bảo percentageOffset được tính đúng cho cả scroll xuống và scroll lên
    let clampedPercentage = min(max(percentageOffset, 0), 1)
    
    if contentOffsetY <= 0 {
      // Trạng thái ban đầu: cell 0 ở full height, y = 0
      cell0Y = 0
      cell0Height = currentFeaturedHeight
      cell0Frame = CGRect(x: 0, y: cell0Y, width: currentWidth, height: cell0Height)
      cell0Bottom = cell0Y + cell0Height
    } else if currentDragOffset > 0 && contentOffsetY <= currentDragOffset {
      // Khi đang scroll để collapse image cell (0 < offset <= dragOffset)
      // Cell 0 giữ nguyên vị trí y = 0, chỉ giảm chiều cao
      cell0Y = 0
      // Chiều cao giảm dần từ featuredHeight về standardHeight
      // Sử dụng clampedPercentage để đảm bảo giá trị trong khoảng 0-1
      let heightDifference = currentFeaturedHeight - currentStandardHeight
      cell0Height = currentFeaturedHeight - (heightDifference * clampedPercentage)
      
      // Đảm bảo chiều cao không nhỏ hơn standardHeight và không lớn hơn featuredHeight
      cell0Height = max(currentStandardHeight, min(cell0Height, currentFeaturedHeight))
      
      cell0Frame = CGRect(x: 0, y: cell0Y, width: currentWidth, height: cell0Height)
      cell0Bottom = cell0Y + cell0Height
    } else {
      // Sau khi image cell đã collapsed hoàn toàn (offset > dragOffset)
      // Cell 0 giữ nguyên ở vị trí y = 0 với chiều cao standardHeight
      // Không di chuyển lên để tránh scroll tự động
      cell0Y = 0
      cell0Height = currentStandardHeight
      cell0Frame = CGRect(x: 0, y: cell0Y, width: currentWidth, height: cell0Height)
      cell0Bottom = cell0Y + cell0Height
    }
    
    // Tính toán frame cho cell 1 (cell thông tin)
    // Logic: Cell 1 luôn bắt đầu từ bottom của cell 0
    // Khi cell 0 collapse, cell 1 di chuyển lên theo
    // Khi scroll tiếp sau collapse, cell 1 scroll để hiển thị nội dung
    let h = height
    let cell1Height = infoCellHeight
    
    var cell1Y: CGFloat = 0
    
    if contentOffsetY <= currentDragOffset {
      // Giai đoạn collapse: Cell 1 di chuyển lên theo cell 0
      // Cell 1 luôn bắt đầu từ bottom của cell 0
      cell1Y = cell0Bottom
    } else {
      // Giai đoạn scroll content: Cell 1 scroll để hiển thị nội dung
      // Khi cell 0 đã collapsed, cell 1 bắt đầu từ standardHeight
      // Khi scroll tiếp, cell 1 di chuyển lên để hiển thị nội dung
      // với padding 180pt ở bottom để luôn trong vùng nhìn thấy
      let scrollOffset = contentOffsetY - currentDragOffset
      let standard = currentStandardHeight
      let visibleArea = h - standard - bottomPadding // Vùng có thể nhìn thấy cho cell 1
      
      // Cell 1 bắt đầu từ standardHeight và di chuyển lên khi scroll
      let initialCell1Y = standard
      let maxScrollOffset = max(0, cell1Height - visibleArea) // Tối đa có thể scroll
      let actualScrollOffset = min(scrollOffset, maxScrollOffset)
      
      cell1Y = initialCell1Y - actualScrollOffset
      
      // Đảm bảo bottom của cell 1 luôn >= (h - bottomPadding)
      // để nội dung luôn trong vùng nhìn thấy
      let minCell1Y = h - bottomPadding - cell1Height
      if cell1Y < minCell1Y {
        cell1Y = minCell1Y
      }
    }
    
    let cell1Frame = CGRect(x: 0, y: cell1Y, width: currentWidth, height: cell1Height)
    
    // Update hoặc tạo cache
    if cache.isEmpty {
      // Tạo mới cache
      let attributes0 = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: 0, section: 0))
      attributes0.zIndex = 0
      attributes0.frame = cell0Frame
      cache.append(attributes0)
      
      let attributes1 = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: 1, section: 0))
      attributes1.zIndex = 1
      attributes1.frame = cell1Frame
      cache.append(attributes1)
    } else {
      // Update cache hiện có (nhanh hơn tạo mới)
      if cache.count > 0 {
        cache[0].zIndex = 0
        cache[0].frame = cell0Frame
      }
      if cache.count > 1 {
        cache[1].zIndex = 1
        cache[1].frame = cell1Frame
      }
    }
  }
  
  // Return all attributes in the cache whose frame intersects with the rect passed to the method 
  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    // Tối ưu: chỉ kiểm tra intersection với cache, không cần tạo array mới nếu không có match
    var layoutAttributes: [UICollectionViewLayoutAttributes] = []
    layoutAttributes.reserveCapacity(cache.count) // Pre-allocate capacity
    
    for attributes in cache {
      if attributes.frame.intersects(rect) {
        layoutAttributes.append(attributes)
      }
    }
    return layoutAttributes.isEmpty ? nil : layoutAttributes
  }
  
  // Return layout attributes for a specific item
  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard indexPath.item < cache.count else { return nil }
    return cache[indexPath.item]
  }
  
  // Return the content offset với snap effect và damping tự nhiên
  override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
    guard let collectionView = collectionView else {
      return proposedContentOffset
    }
    
    let currentOffset = collectionView.contentOffset.y
    let proposedY = proposedContentOffset.y
    let currentDragOffset = dragOffset
    let h = height
    let contentSize = collectionViewContentSize
    let maxOffset = max(0, contentSize.height - h)
    
    // Giới hạn offset trong phạm vi hợp lệ
    let clampedProposedY = max(0, min(proposedY, maxOffset))
    
    // Nếu đã vượt qua dragOffset, cho phép scroll tự nhiên (không snap)
    if clampedProposedY > currentDragOffset {
      return CGPoint(x: 0, y: clampedProposedY)
    }
    
    // Nếu đang ở vùng collapse (0 <= proposedY <= dragOffset)
    if clampedProposedY >= 0 && clampedProposedY <= currentDragOffset {
      // Nếu scroll xuống và gần mốc dragOffset, có thể snap về dragOffset
      if velocity.y > 0.3 && clampedProposedY > currentDragOffset - dampingThreshold {
        // Snap về dragOffset khi scroll xuống với velocity đủ lớn
        return CGPoint(x: 0, y: currentDragOffset)
      }
      
      // Nếu scroll lên từ vùng content về vùng collapse, áp dụng damping
      if currentOffset > currentDragOffset && clampedProposedY < currentDragOffset {
        return applyDamping(to: clampedProposedY, around: currentDragOffset, velocity: velocity.y)
      }
      
      // Cho phép scroll tự do trong vùng collapse
      return CGPoint(x: 0, y: clampedProposedY)
    }
    
    // Mặc định: trả về proposed offset
    return CGPoint(x: 0, y: clampedProposedY)
  }
  
  // Áp dụng damping khi scroll ngược lại để tạo hiệu ứng mượt mà, tự nhiên
  private func applyDamping(to offset: CGFloat, around snapPoint: CGFloat, velocity: CGFloat) -> CGPoint {
    let distance = abs(offset - snapPoint)
    
    // Nếu quá xa snap point, không áp dụng damping
    if distance > dampingThreshold {
      return CGPoint(x: 0, y: offset)
    }
    
    // Tính toán damping dựa trên khoảng cách và velocity
    // Velocity càng lớn thì damping càng yếu (cho phép scroll nhanh hơn)
    let velocityFactor = min(abs(velocity) / 2.0, 1.0) // Normalize velocity
    let distanceRatio = distance / dampingThreshold
    
    // Damping mạnh hơn khi gần snap point và velocity thấp
    let effectiveDamping = dampingFactor * (1.0 - velocityFactor * 0.5) * (1.0 - distanceRatio * 0.5)
    
    // Áp dụng damping
    let direction = offset < snapPoint ? -1.0 : 1.0
    let dampedOffset = snapPoint + (offset - snapPoint) * (1.0 - effectiveDamping)
    
    return CGPoint(x: 0, y: dampedOffset)
  }
  
  // Tối ưu: chỉ invalidate khi bounds thực sự thay đổi hoặc khi scroll
  override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    guard let collectionView = collectionView else { return false }
    
    // Invalidate nếu bounds thay đổi kích thước
    let oldBounds = collectionView.bounds
    if oldBounds.size != newBounds.size {
      cachedBounds = .zero // Reset cache khi bounds thay đổi
      cachedContentSize = .zero
      return true
    }
    
    // Với parallax effect, cần invalidate khi scroll để đảm bảo hiệu ứng mượt mà
    // Đây là cần thiết cho parallax effect
    return true
  }
  
}
