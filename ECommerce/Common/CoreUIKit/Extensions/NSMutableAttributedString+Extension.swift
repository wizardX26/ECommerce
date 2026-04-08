import UIKit

extension NSTextAttachment {
    func setImageHeight(height: CGFloat) {
        guard let image = image else { return }
        let ratio = image.size.width / image.size.height

        bounds = CGRect(x: bounds.origin.x, y: bounds.origin.y, width: ratio * height, height: height)
    }
}

extension NSMutableAttributedString {
    @discardableResult
    func bold(_ text: String, size: CGFloat) -> NSMutableAttributedString {
        let attrs: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: size)]
        let boldString = NSMutableAttributedString(string: text, attributes: attrs)
        append(boldString)
        return self
    }
    
    @discardableResult
    func icon(_ icon: UIImage?, font: UIFont? = nil) -> NSMutableAttributedString {
        let attachment = NSTextAttachment()
        attachment.image = icon
        if let font = font {
            attachment.setImageHeight(height: font.lineHeight)

            let bounds = attachment.bounds
            let mid = font.descender + font.capHeight
            attachment.bounds = CGRect(x: 0,
                                       y: font.descender - bounds.size.height / 2 + mid + 2,
                                       width: bounds.size.width,
                                       height: bounds.size.height).integral
        }
        // wrap the attachment in its own attributed string so we can append it
        let imageString = NSAttributedString(attachment: attachment)
        append(imageString)
        return self
    }
    
    @discardableResult
    func normal(_ text: String) -> NSMutableAttributedString {
        let normal = NSAttributedString(string: text)
        append(normal)
        return self
    }
    
    @discardableResult
    func text(_ text: String, font: UIFont = UIFont.systemFont(ofSize: 14)) -> NSMutableAttributedString {
        let attrs: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
        let boldString = NSMutableAttributedString(string:text, attributes: attrs)
        append(boldString)
        return self
    }
    
    @discardableResult
    func text(_ text: String, font: UIFont? = nil, color: UIColor? = nil) -> NSMutableAttributedString {
        var attrs: [NSAttributedString.Key: Any] = [NSAttributedString.Key: Any]()
        if let color = color {
            attrs[NSAttributedString.Key.foregroundColor] = color
        }
        if let font = font {
            attrs[NSAttributedString.Key.font] = font
        }
        let boldString = NSMutableAttributedString(string:text, attributes: attrs)
        append(boldString)
        return self
    }
    
}
