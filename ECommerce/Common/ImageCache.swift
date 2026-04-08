import UIKit
import Foundation
import CommonCrypto

protocol ImageCacheService {
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void)
    func cacheImage(_ image: UIImage, for url: URL)
}

final class DefaultImageCacheService: ImageCacheService {
    
    static let shared = DefaultImageCacheService()
    
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let urlCache: URLCache
    
    init() {
        // Setup URLCache với memory và disk cache
        let memoryCapacity = 50 * 1024 * 1024 // 50MB
        let diskCapacity = 200 * 1024 * 1024  // 200MB
        urlCache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: "ImageCache")
        
        // Setup file system cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesDirectory.appendingPathComponent("ImageCache", isDirectory: true)
        
        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        printIfDebug("[ImageCache] Loading image - URL: \(url.lastPathComponent)")
        
        // 1. Check URLCache first (memory cache)
        if let cachedResponse = urlCache.cachedResponse(for: URLRequest(url: url)),
           let image = UIImage(data: cachedResponse.data) {
            printIfDebug("[ImageCache] Image loaded from URLCache - URL: \(url.lastPathComponent)")
            DispatchQueue.main.async {
                completion(image)
            }
            return
        }
        
        // 2. Check file system cache
        let fileName = url.absoluteString.md5
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            printIfDebug("[ImageCache] Image loaded from file cache - URL: \(url.lastPathComponent), Size: \(data.count) bytes")
            // Also store in URLCache for faster access next time
            let response = URLResponse(url: url, mimeType: "image/jpeg", expectedContentLength: data.count, textEncodingName: nil)
            let cachedResponse = CachedURLResponse(response: response, data: data)
            urlCache.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
            DispatchQueue.main.async {
                completion(image)
            }
            return
        }
        
        // 3. Load from network
        printIfDebug("[ImageCache] Loading image from network - URL: \(url.lastPathComponent)")
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10)
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let data = data,
                  let image = UIImage(data: data),
                  let response = response else {
                printIfDebug("[ImageCache] Image load failed - URL: \(url.lastPathComponent), Error: \(error?.localizedDescription ?? "Unknown")")
                // If network fails, return nil (will show placeholder)
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            printIfDebug("[ImageCache] Image loaded from network - URL: \(url.lastPathComponent), Size: \(data.count) bytes")
            
            // Cache in URLCache
            let cachedResponse = CachedURLResponse(response: response, data: data)
            self?.urlCache.storeCachedResponse(cachedResponse, for: request)
            
            // Cache in file system
            self?.cacheImage(image, for: url)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    func cacheImage(_ image: UIImage, for url: URL) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        let fileName = url.absoluteString.md5
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            printIfDebug("[ImageCache] Image cached to file - URL: \(url.lastPathComponent), Size: \(data.count) bytes")
        } catch {
            printIfDebug("[ImageCache] Failed to cache image - URL: \(url.lastPathComponent), Error: \(error.localizedDescription)")
        }
    }
}

// MARK: - String MD5 Extension
private extension String {
    var md5: String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_MD5(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

