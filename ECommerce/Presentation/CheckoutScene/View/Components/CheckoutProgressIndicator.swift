//
//  CheckoutProgressIndicator.swift
//  ECommerce
//
//  Created by wizard.os25 on 15/1/26.
//

import UIKit

/// Progress indicator component showing checkout steps: O--O--O--O
class CheckoutProgressIndicator: UIView {
    
    enum Step: Int {
        case placeOrder = 0
        case confirmPayment = 1
        case success = 2
    }
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var stepViews: [StepView] = []
    private var connectorViews: [UIView] = []
    
    private lazy var stepTitles: [String] = ["step_place_order".localized(), "step_confirm_payment".localized(), "step_success".localized()]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        addSubview(stackView)
        
        // Create step views
        for (index, title) in stepTitles.enumerated() {
            let stepView = StepView(title: title)
            stepView.tag = index
            stepViews.append(stepView)
            stackView.addArrangedSubview(stepView)
            
            // Add connector line (except for last item)
            if index < stepTitles.count - 1 {
                let connector = UIView()
                connector.backgroundColor = Colors.tokenDark20
                connector.translatesAutoresizingMaskIntoConstraints = false
                connectorViews.append(connector)
                stackView.addArrangedSubview(connector)
                
                NSLayoutConstraint.activate([
                    connector.heightAnchor.constraint(equalToConstant: 2),
                    connector.widthAnchor.constraint(equalToConstant: 40)
                ])
            }
        }
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Initial state: all steps inactive
        updateProgress(to: .placeOrder)
    }
    
    func updateProgress(to step: Step) {
        for (index, stepView) in stepViews.enumerated() {
            if index <= step.rawValue {
                stepView.setCompleted(true)
            } else {
                stepView.setCompleted(false)
            }
        }
        
        // Update connector lines: đổi màu đường nối từ bước đã hoàn thành
        for (index, connector) in connectorViews.enumerated() {
            if index < step.rawValue {
                // Đường nối từ bước đã hoàn thành sang bước tiếp theo
                connector.backgroundColor = Colors.tokenRainbowBlueEnd
            } else {
                // Đường nối chưa hoàn thành
                connector.backgroundColor = Colors.tokenDark20
            }
        }
    }
    
    /// Mark success step as completed with red color to indicate payment completion
    func setSuccessStepCompleted() {
        // Update to success step
        updateProgress(to: .success)
        
        // Set success step (last step) to red color
        if let successStepView = stepViews.last {
            successStepView.setSuccessCompleted()
        }
        
        // Ensure connector between confirmPayment and success is filled
        if connectorViews.count >= 1 {
            connectorViews[1].backgroundColor = Colors.tokenRainbowBlueEnd // Tô đầy connector cuối cùng
        }
    }
}

private class StepView: UIView {
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Typography.fontRegular12
        label.textColor = Colors.tokenDark60
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let title: String
    
    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        
        titleLabel.text = title
        
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        setCompleted(false)
    }
    
    func setCompleted(_ completed: Bool) {
        let bundle = Bundle.main
        if completed {
            // Use ic_radio_check for completed steps
            iconImageView.image = HelperFunction.getImage(named: "ic_radio_check", in: bundle)
            titleLabel.textColor = Colors.tokenRainbowBlueEnd
        } else {
            // Use ic_new_tick_not_select for incomplete steps
            iconImageView.image = HelperFunction.getImage(named: "ic_new_tick_not_select", in: bundle)
            titleLabel.textColor = Colors.tokenDark60
        }
    }
    
    /// Mark as success completed with red color (for payment success step)
    func setSuccessCompleted() {
        let bundle = Bundle.main
        // Use ic_radio_check for completed steps
        iconImageView.image = HelperFunction.getImage(named: "ic_radio_check", in: bundle)
        // Use red color to indicate payment completion
        titleLabel.textColor = Colors.tokenRed100
    }
}
