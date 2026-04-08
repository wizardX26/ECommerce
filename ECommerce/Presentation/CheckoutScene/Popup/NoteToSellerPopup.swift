//
//  NoteToSellerPopup.swift
//  ECommerce
//
//  Created by wizard.os25 on 15/1/26.
//

import UIKit

final class NoteToSellerPopup: UIView {
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "note_to_seller".localized()
        label.font = Typography.fontBold18
        label.textColor = Colors.tokenDark100
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = Typography.fontRegular16
        tv.textColor = Colors.tokenDark100
        tv.layer.borderWidth = 1
        tv.layer.borderColor = Colors.tokenDark10.cgColor
        tv.layer.cornerRadius = 8
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("submit".localized(), for: .normal)
        button.titleLabel?.font = Typography.fontBold16
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = Colors.tokenRainbowBlueEnd
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("cancel".localized(), for: .normal)
        button.titleLabel?.font = Typography.fontRegular16
        button.setTitleColor(Colors.tokenDark60, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var onSave: ((String?) -> Void)? // Changed to optional String
    private var onCancel: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        addSubview(overlayView)
        addSubview(containerView)
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(textView)
        containerView.addSubview(submitButton)
        containerView.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -28), // Hiển thị cao lên 28pt
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            textView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 120),
            
            submitButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16),
            submitButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            submitButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            submitButton.heightAnchor.constraint(equalToConstant: 48),
            
            cancelButton.topAnchor.constraint(equalTo: submitButton.bottomAnchor, constant: 12),
            cancelButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        let overlayTap = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        overlayView.addGestureRecognizer(overlayTap)
    }
    
    func configure(
        initialNote: String?,
        onSave: @escaping (String?) -> Void, // Changed to optional String
        onCancel: @escaping () -> Void
    ) {
        self.onSave = onSave
        self.onCancel = onCancel
        textView.text = initialNote
    }
    
    func show(in parentView: UIView) {
        parentView.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: parentView.topAnchor),
            self.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ])
        
        overlayView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.3) {
            self.overlayView.alpha = 1
            self.containerView.transform = .identity
        } completion: { _ in
            self.textView.becomeFirstResponder()
        }
    }
    
    func dismiss() {
        textView.resignFirstResponder()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.overlayView.alpha = 0
            self.containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }) { _ in
            self.removeFromSuperview()
        }
    }
    
    @objc private func submitTapped() {
        // Allow empty note (optional field)
        let note = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave?(note.isEmpty ? nil : note)
    }
    
    @objc private func cancelTapped() {
        onCancel?()
    }
    
    @objc private func overlayTapped() {
        dismiss()
    }
}
