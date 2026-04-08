//
//  AccountObject.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//

import UIKit

extension UILabel {
    func setTextFont(for string: String, font: UIFont, color: UIColor) {
        guard let text = text else {
            return
        }
        
        let range = (text as NSString).range(of: string)
        
        let attribute = NSMutableAttributedString(string: text)
        attribute.addAttribute(NSAttributedString.Key.font, value: font, range: range)
        attribute.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: range)
        
        attributedText = attribute
    }
    
    func setAttributedText(_ subTexts: [AttributedText]) {
        guard let text = text else {
            return
        }
        
        let attributed = NSMutableAttributedString(string: text)
        for subText in subTexts {
            let range = (text as NSString).range(of: subText.text ?? "")
            if let subTextFont = subText.font {
                attributed.addAttribute(NSAttributedString.Key.font, value: subTextFont, range: range)
            }
            if let subTextColor = subText.color {
                attributed.addAttribute(NSAttributedString.Key.foregroundColor, value: subTextColor, range: range)
            }
        }
        
        attributedText = attributed
    }
    
    func dropShadow(radius: CGFloat, opacity: Float, offset: CGSize, color: UIColor) {
        self.layer.masksToBounds = false
        self.layer.shadowRadius = radius
        self.layer.shadowOpacity = opacity
        self.layer.shadowOffset = offset
        self.layer.shadowColor = color.cgColor
    }
    
    func setLineSpacing(lineSpacing: CGFloat = 0.0, lineHeightMultiple: CGFloat = 0.0) {
        
        guard let labelText = self.text else {
            return
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        // paragraphStyle.alignment = .center
        
        let attributedString:NSMutableAttributedString
        if let labelattributedText = self.attributedText {
            attributedString = NSMutableAttributedString(attributedString: labelattributedText)
        } else {
            attributedString = NSMutableAttributedString(string: labelText)
        }
        
        let range = (labelText as NSString).range(of: labelText)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: range)
        
        self.attributedText = attributedString
    }
	
	func setUnderlineLabel(range: String, content: String) {
		let underlineAttriString = NSMutableAttributedString(string: content)
		let range = (content as NSString).range(of: range)
		underlineAttriString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
		self.attributedText = underlineAttriString
	}
}
