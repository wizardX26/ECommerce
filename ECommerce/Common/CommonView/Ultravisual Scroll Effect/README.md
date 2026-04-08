# Ultravisual Scroll Effect - Hướng dẫn Tích hợp

## Tổng quan

Hiệu ứng scroll này tạo ra một màn hình chi tiết sản phẩm với 2 cells:
- **Cell ảnh (index 0)**: Chiếm nửa màn hình ở trên, có hiệu ứng thu vào khi scroll
- **Cell thông tin (index 1)**: Ở dưới, có thể scroll dài để xem nhiều nội dung

Khi scroll xuống, cell ảnh sẽ thu vào từ nửa màn hình về kích thước nhỏ hơn (100px), và cell thông tin sẽ scroll bình thường để hiển thị nội dung.

## Cấu trúc File

Project này bao gồm các file chính:

```
Ultravisual/
├── UltravisualLayout.swift          # Custom layout cho hiệu ứng scroll
├── InspirationCell.swift            # Cell hiển thị (có thể đổi tên)
├── Inspiration.swift                 # Model (có thể đổi tên)
└── InspirationsViewController.swift # ViewController (có thể đổi tên)
```

## Các File Cần Thiết

### 1. UltravisualLayout.swift

File này chứa custom `UICollectionViewLayout` tạo ra hiệu ứng scroll. **Đây là file quan trọng nhất**, bạn cần copy toàn bộ file này vào project của bạn.

**Các tham số có thể tùy chỉnh:**
- `standardHeight`: Chiều cao của cell ảnh khi collapsed (mặc định: 100)
- `featuredHeight`: Chiều cao của cell ảnh khi expanded (mặc định: `height / 2` - nửa màn hình)
- Content size: Điều chỉnh trong `collectionViewContentSize` để cho phép scroll nhiều hay ít

### 2. InspirationCell.swift

Cell hiển thị với các IBOutlet:
- `imageView`: Hiển thị ảnh sản phẩm
- `imageCoverView`: View overlay với hiệu ứng alpha
- `titleLabel`: Label tiêu đề

**Lưu ý:** Bạn có thể đổi tên class và thêm các UI elements khác tùy nhu cầu.

### 3. Inspiration.swift

Model đơn giản với:
- `title`: String
- `backgroundImage`: UIImage?
- `imageURL`: String? (để load ảnh từ API)

### 4. InspirationsViewController.swift

ViewController sử dụng `UICollectionViewController` với custom layout.

## Cách Tích hợp vào Project Mới

### Bước 1: Copy Files

1. Copy `UltravisualLayout.swift` vào project của bạn
2. Copy các file khác (Cell, Model, ViewController) hoặc tạo mới dựa trên template

### Bước 2: Setup Storyboard

1. Tạo một `UICollectionViewController` trong Storyboard
2. Set Custom Class của Collection View Controller thành class ViewController của bạn
3. Set Custom Class của Collection View Layout thành `UltravisualLayout`
4. Tạo prototype cell với:
   - Reuse Identifier: `InspirationCell` (hoặc tên bạn muốn)
   - Custom Class: `InspirationCell` (hoặc tên bạn muốn)
   - Thêm các IBOutlet: `imageView`, `imageCoverView`, `titleLabel`

### Bước 3: Kết nối IBOutlets

Trong Storyboard, kết nối các IBOutlet từ cell đến các UI elements:
- `imageView` → UIImageView
- `imageCoverView` → UIView (overlay)
- `titleLabel` → UILabel

### Bước 4: Cập nhật Code

#### ViewController

```swift
import UIKit

class YourViewController: UICollectionViewController {
  var product: YourProductModel?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView?.backgroundColor = .clear
    collectionView?.decelerationRate = .fast
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 2 // Cell ảnh (0) và cell thông tin (1)
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: "YourCellIdentifier", for: indexPath)
      as? YourCellClass else {
        return UICollectionViewCell()
    }
    
    if indexPath.item == 0 {
      // Cell ảnh
      cell.configure(with: product)
      cell.backgroundColor = .clear
    } else {
      // Cell thông tin
      cell.backgroundColor = .white
      // Configure cell với thông tin sản phẩm
    }
    
    return cell
  }
}
```

#### Model

```swift
class YourProductModel {
  var title: String
  var image: UIImage?
  var imageURL: String?
  
  init(title: String = "", image: UIImage? = nil, imageURL: String? = nil) {
    self.title = title
    self.image = image
    self.imageURL = imageURL
  }
}
```

## Tích hợp với API

### Load ảnh từ URL

```swift
func loadProductImage(from urlString: String) {
  guard let url = URL(string: urlString) else { return }
  
  URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
    guard let data = data, let image = UIImage(data: data) else { return }
    
    DispatchQueue.main.async {
      self?.product?.backgroundImage = image
      self?.collectionView?.reloadItems(at: [IndexPath(item: 0, section: 0)])
    }
  }.resume()
}
```

### Sử dụng trong ViewController

```swift
override func viewDidLoad() {
  super.viewDidLoad()
  
  // Load data từ API
  loadProductFromAPI { [weak self] productData in
    self?.product = YourProductModel(
      title: productData.title,
      imageURL: productData.imageURL
    )
    
    // Load ảnh từ URL
    if let imageURL = productData.imageURL {
      self?.loadProductImage(from: imageURL)
    }
    
    self?.collectionView?.reloadData()
  }
}
```

## Tùy chỉnh

### Thay đổi kích thước Cell ảnh

Trong `UltravisualLayout.swift`:

```swift
struct UltravisualLayoutConstants {
  struct Cell {
    static let standardHeight: CGFloat = 100 // Chiều cao khi collapsed
  }
}

// Trong class UltravisualLayout:
var featuredHeight: CGFloat {
  return height / 2 // Chiều cao khi expanded (nửa màn hình)
  // Hoặc giá trị cố định: return 300
}
```

### Thay đổi Content Size (độ dài scroll)

Trong `UltravisualLayout.swift`, method `collectionViewContentSize`:

```swift
override var collectionViewContentSize : CGSize {
  // Cho phép scroll 3 màn hình
  let minContentHeight = standardHeight + height * 3
  return CGSize(width: width, height: minContentHeight)
}
```

### Tắt Snap Effect

Trong `UltravisualLayout.swift`, method `targetContentOffset`:

```swift
override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
  // Trả về proposedContentOffset trực tiếp để tắt snap
  return proposedContentOffset
}
```

### Thay đổi tốc độ Scroll

Trong ViewController:

```swift
override func viewDidLoad() {
  super.viewDidLoad()
  collectionView?.decelerationRate = .fast // hoặc .normal, .fast
}
```

## Hiệu ứng Visual

Hiệu ứng scroll bao gồm:

1. **Alpha Animation**: `imageCoverView` thay đổi alpha từ 0.75 về 0.3 khi cell collapse
2. **Scale Animation**: `titleLabel` scale từ 1.0 về 0.5 khi cell collapse
3. **Height Animation**: Cell ảnh thu vào từ `featuredHeight` về `standardHeight`

Các hiệu ứng này được tính toán tự động trong `InspirationCell.apply(_:)` method.

## Lưu ý Quan trọng

1. **Z-Index**: 
   - Cell ảnh có `zIndex = 0`
   - Cell thông tin có `zIndex = 1` (nằm trên)

2. **Content Size**: Phải đủ lớn để cho phép scroll. Nếu không scroll được, kiểm tra `collectionViewContentSize`.

3. **Performance**: Layout được invalidate mỗi khi scroll (`shouldInvalidateLayout` trả về `true`), đảm bảo hiệu ứng mượt mà.

4. **Memory**: Nếu load nhiều ảnh từ API, nên implement image caching để tránh load lại nhiều lần.

## Troubleshooting

### Không scroll được hết hành trình
- Kiểm tra `collectionViewContentSize` có đủ lớn không
- Kiểm tra `targetContentOffset` có cho phép scroll tự do sau `dragOffset` không

### Cell ảnh không collapse
- Kiểm tra `dragOffset` có được tính đúng không
- Kiểm tra `nextItemPercentageOffset` có trong khoảng 0-1 không

### Layout bị lỗi
- Đảm bảo `numberOfItems` trả về đúng 2
- Kiểm tra frame của các cell trong `prepare()` method

## Ví dụ Hoàn chỉnh

Xem các file trong project này để tham khảo implementation đầy đủ:
- `UltravisualLayout.swift`: Custom layout
- `InspirationCell.swift`: Cell implementation
- `Inspiration.swift`: Model
- `InspirationsViewController.swift`: ViewController

## License

Copyright (c) 2018 Razeware LLC
