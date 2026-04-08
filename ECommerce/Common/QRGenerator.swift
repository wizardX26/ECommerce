//
//  QRGenerator.swift
//  ViettelPay
//
//  Created by Tran Vuong Minh on 8/6/20.
//  Copyright © 2020 Viettel. All rights reserved.
//

import Foundation
import UIKit

public class QRGenerator: NSObject {
	// swiftlint: disable identifier_name
	enum ErrorCorrection: String {
		case Low = "L"
		case Medium = "M"
		case Quartile = "Q"
		case High = "H"
	}
	
	let data: Data
	let logo: UIImage?
	var errorCorrection = ErrorCorrection.Medium
	
	public var ciImage: CIImage? {
		// Generate QRCode
		guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {
			return nil
		}
		qrFilter.setDefaults()
		qrFilter.setValue(data, forKey: "inputMessage")
		qrFilter.setValue(self.errorCorrection.rawValue, forKey: "inputCorrectionLevel")
		if let cg = logo?.cgImage {
			let ci = CIImage(cgImage: cg)
			return qrFilter.outputImage?.combined(with: ci)
		}
		return qrFilter.outputImage
	}
	
	public init(data: Data, logo: UIImage? = nil) {
		self.data = data
		self.logo = logo
		super.init()
	}
	
	public func image(size: CGSize) -> UIImage? {
		guard let ciImage = ciImage else {
			return nil
		}
		
		// Size
		let ciImageSize = ciImage.extent.size
		let widthRatio = size.width / ciImageSize.width
		let heightRatio = size.height / ciImageSize.height
		let transform = CGAffineTransform(scaleX: widthRatio, y: heightRatio)
		return UIImage(ciImage: ciImage.transformed(by: transform), scale: 0, orientation: UIImage.Orientation.up)
	}
	
}

fileprivate extension CIImage {
	
	/// Combines the current image with the given image centered.
	func combined(with image: CIImage) -> CIImage? {
		guard let combinedFilter = CIFilter(name: "CISourceOverCompositing") else {
			return nil
		}
		let scaleX = (extent.size.width / image.extent.width) * 0.3
		let scaledImage = image.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleX))
		let centerTransform = CGAffineTransform(translationX: extent.midX - (scaledImage.extent.size.width / 2), y: extent.midY - (scaledImage.extent.size.height / 2))
		combinedFilter.setValue(scaledImage.transformed(by: centerTransform), forKey: "inputImage")
		combinedFilter.setValue(self, forKey: "inputBackgroundImage")
		
		return combinedFilter.outputImage
	}
}
