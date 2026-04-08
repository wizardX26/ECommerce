//
//  ProfileTableViewCell.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import UIKit

final class ProfileTableViewCell: UITableViewCell {
    
    @IBOutlet private var profileTitleLabel: UILabel!
    @IBOutlet private var profileSubtitleLabel: UILabel!
    
    private var onNotVerifyLabelTap: (() -> Void)?
    private var notVerifyLabel: UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        profileTitleLabel.text = nil
        profileSubtitleLabel.text = nil
        profileSubtitleLabel.attributedText = nil
        notVerifyLabel?.removeFromSuperview()
        notVerifyLabel = nil
        onNotVerifyLabelTap = nil
    }
    
    // MARK: - Configuration
    
    func fill(with title: String, subtitle: String?) {
        profileTitleLabel.text = title
        profileSubtitleLabel.text = subtitle
        profileSubtitleLabel.attributedText = nil
        profileSubtitleLabel.isHidden = subtitle == nil || subtitle?.isEmpty == true
    }
    
    func fill(with title: String, subtitle: String?, showNotVerify: Bool, onNotVerifyTap: (() -> Void)?) {
        profileTitleLabel.text = title
        profileSubtitleLabel.isHidden = false
        
        if showNotVerify {
            // Create attributed string với email + "notVerify" label
            let baseAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.gray
            ]
            
            let attributedText = NSMutableAttributedString(
                string: subtitle ?? "",
                attributes: baseAttributes
            )
            
            let notVerifyText = NSAttributedString(
                string: " notVerify",
                attributes: [
                    .font: UIFont.italicSystemFont(ofSize: 14),
                    .foregroundColor: Colors.tokenRainbowBlueEnd
                ]
            )
            attributedText.append(notVerifyText)
            
            profileSubtitleLabel.attributedText = attributedText
            
            // Add tap gesture để detect tap vào "notVerify"
            if notVerifyLabel == nil {
                setupNotVerifyTapGesture(onTap: onNotVerifyTap)
            }
            onNotVerifyLabelTap = onNotVerifyTap
        } else {
            profileSubtitleLabel.text = subtitle
            profileSubtitleLabel.attributedText = nil
            profileSubtitleLabel.isHidden = subtitle == nil || subtitle?.isEmpty == true
            notVerifyLabel?.removeFromSuperview()
            notVerifyLabel = nil
        }
    }
    
    // MARK: - Private
    
    private func setupViews() {
        // Title configuration
        profileTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        profileTitleLabel.textColor = .label
        
        // Subtitle configuration
        profileSubtitleLabel.font = UIFont.systemFont(ofSize: 14)
        profileSubtitleLabel.textColor = .gray
        profileSubtitleLabel.isUserInteractionEnabled = true
        
        // Cell configuration
        accessoryType = .disclosureIndicator
        selectionStyle = .default
    }
    
    private func setupNotVerifyTapGesture(onTap: (() -> Void)?) {
        // Remove existing gesture recognizers
        profileSubtitleLabel.gestureRecognizers?.forEach { profileSubtitleLabel.removeGestureRecognizer($0) }
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSubtitleTap(_:)))
        profileSubtitleLabel.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleSubtitleTap(_ gesture: UITapGestureRecognizer) {
        guard let label = profileSubtitleLabel, let attributedText = label.attributedText else { return }
        
        let location = gesture.location(in: label)
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: label.bounds.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.lineBreakMode = label.lineBreakMode
        layoutManager.addTextContainer(textContainer)
        
        let characterIndex = layoutManager.characterIndex(for: location, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        // Check if tap is within "notVerify" range (assume "notVerify" starts after email)
        let emailText = label.text?.replacingOccurrences(of: " notVerify", with: "") ?? ""
        let notVerifyRange = NSRange(location: emailText.count, length: " notVerify".count)
        
        if NSLocationInRange(characterIndex, notVerifyRange) {
            onNotVerifyLabelTap?()
        }
    }
}
