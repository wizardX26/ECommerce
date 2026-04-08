//
//  ProfileImagePickerPopup.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import UIKit

final class ProfileImagePickerPopup: UIView {
    
    @IBOutlet private weak var chooseFromPhotosLabel: UILabel!
    @IBOutlet private weak var openCameraLabel: UILabel!
    @IBOutlet private weak var cancelLabel: UILabel!
    @IBOutlet private weak var contentView: UIView!
    
    private var dimmedView: UIView?
    
    var onChooseFromPhotos: (() -> Void)?
    var onOpenCamera: (() -> Void)?
    var onCancel: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    // MARK: - Setup
    
    private func commonInit() {
        Bundle.main.loadNibNamed("ProfileImagePickerPopup", owner: self, options: nil)
        guard let contentView = contentView else {
            fatalError("ProfileImagePickerPopup.xib doesn't exist or contentView outlet is not connected")
        }
        
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)
        
        // Setup views after loading from XIB
        setupViews()
    }
    
    private func setupViews() {
        // Configure labels
        chooseFromPhotosLabel.text = "Choose on Photos"
        chooseFromPhotosLabel.font = UIFont.systemFont(ofSize: 16)
        chooseFromPhotosLabel.textColor = .label
        chooseFromPhotosLabel.textAlignment = .center
        
        openCameraLabel.text = "Open camera"
        openCameraLabel.font = UIFont.systemFont(ofSize: 16)
        openCameraLabel.textColor = .label
        openCameraLabel.textAlignment = .center
        
        cancelLabel.text = "Cancel"
        cancelLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        cancelLabel.textColor = .systemRed
        cancelLabel.textAlignment = .center
        
        // Add separator lines between cells programmatically
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Add separator line below chooseFromPhotosLabel
            let separator1 = UIView()
            separator1.backgroundColor = Colors.tokenDark10
            separator1.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.addSubview(separator1)
            
            // Add separator line below openCameraLabel
            let separator2 = UIView()
            separator2.backgroundColor = Colors.tokenDark10
            separator2.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.addSubview(separator2)
            
            NSLayoutConstraint.activate([
                // Separator 1: between chooseFromPhotos and openCamera
                separator1.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 16),
                separator1.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16),
                separator1.topAnchor.constraint(equalTo: self.chooseFromPhotosLabel.bottomAnchor),
                separator1.heightAnchor.constraint(equalToConstant: 1),
                
                // Separator 2: between openCamera and cancel
                separator2.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 16),
                separator2.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -16),
                separator2.topAnchor.constraint(equalTo: self.openCameraLabel.bottomAnchor),
                separator2.heightAnchor.constraint(equalToConstant: 1)
            ])
        }
        
        // Setup tap gestures
        let chooseFromPhotosTap = UITapGestureRecognizer(target: self, action: #selector(handleChooseFromPhotos))
        chooseFromPhotosLabel.isUserInteractionEnabled = true
        chooseFromPhotosLabel.addGestureRecognizer(chooseFromPhotosTap)
        
        let openCameraTap = UITapGestureRecognizer(target: self, action: #selector(handleOpenCamera))
        openCameraLabel.isUserInteractionEnabled = true
        openCameraLabel.addGestureRecognizer(openCameraTap)
        
        let cancelTap = UITapGestureRecognizer(target: self, action: #selector(handleCancel))
        cancelLabel.isUserInteractionEnabled = true
        cancelLabel.addGestureRecognizer(cancelTap)
        
        // Configure popup appearance
        backgroundColor = .systemBackground
        layer.cornerRadius = 16
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        clipsToBounds = true
    }
    
    // MARK: - Actions
    
    @objc private func handleChooseFromPhotos() {
        onChooseFromPhotos?()
        dismiss()
    }
    
    @objc private func handleOpenCamera() {
        onOpenCamera?()
        dismiss()
    }
    
    @objc private func handleCancel() {
        onCancel?()
        dismiss()
    }
    
    // MARK: - Show/Dismiss
    
    func show(in parentView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        
        // Create dimmed background
        let dimmed = UIView(frame: parentView.bounds)
        dimmed.translatesAutoresizingMaskIntoConstraints = false
        dimmed.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        dimmedView = dimmed
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismiss))
        dimmed.addGestureRecognizer(tap)
        
        parentView.addSubview(dimmed)
        parentView.addSubview(self)
        
        NSLayoutConstraint.activate([
            // Dimmed view constraints
            dimmed.topAnchor.constraint(equalTo: parentView.topAnchor),
            dimmed.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            dimmed.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            dimmed.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            
            // Popup constraints - bottom of screen, height 280
            leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            heightAnchor.constraint(equalToConstant: 280)
        ])
        
        // Animate in
        alpha = 0
        dimmed.alpha = 0
        transform = CGAffineTransform(translationX: 0, y: 280)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            dimmed.alpha = 1
            self.transform = .identity
        }
    }
    
    @objc func dismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
            self.dimmedView?.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: 280)
        }, completion: { _ in
            self.dimmedView?.removeFromSuperview()
            self.removeFromSuperview()
        })
    }
}
