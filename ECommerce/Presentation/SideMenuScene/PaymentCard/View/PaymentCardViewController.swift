//
//  PaymentCardViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 14/1/26.
//

import UIKit
import Stripe
import StripePayments

final class PaymentCardViewController: EcoViewController {
    
    // MARK: - UI Components
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var addCardButton: EcoButton!
    
    private var paymentCardController: PaymentCardController! {
        get { controller as? PaymentCardController }
    }
    
    private var cardTextField: STPPaymentCardTextField?
    private var cardTextFieldCell: UITableViewCell?
    
    // MARK: - Lifecycle
    
    static func create(
        with paymentCardController: PaymentCardController
    ) -> PaymentCardViewController {
        let view = PaymentCardViewController.instantiateViewController()
        view.controller = paymentCardController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isSwipeBackEnabled = true
        setupViews()
        bindPaymentCardSpecific()
        paymentCardController.didLoadView()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindPaymentCardSpecific()
    }
    
    override func applyNavigation(_ state: EcoNavigationState) {
        super.applyNavigation(state)
        // Override left item tap callback to pop back normally
        DispatchQueue.main.async { [weak self] in
            if let navBarController = self?.navigationBarViewController?.controller as? DefaultEcoNavigationBarController {
                navBarController.onLeftItemTap = { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    // MARK: - PaymentCard-Specific Binding
    
    private func bindPaymentCardSpecific() {
        paymentCardController.paymentCards.observe(on: self) { [weak self] _ in
            self?.tableView.reloadData()
        }
        
        paymentCardController.screenTitle.observe(on: self) { [weak self] title in
            self?.updateNavigationTitle(title)
        }
        
        paymentCardController.successMessage.observe(on: self) { [weak self] message in
            guard let self = self, let message = message, !message.isEmpty else { return }
            self.showSuccessAlert(message: message)
            // Clear card input after success
            self.cardTextField?.clear()
        }
        
        paymentCardController.error.observe(on: self) { [weak self] error in
            guard let self = self, let error = error else { return }
            self.showAlert(title: "error".localized(), message: error.localizedDescription)
        }
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        // Setup TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.backgroundColor = .systemBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CardInputCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SavedCardCell")
        
        // Setup Add Card Button
        addCardButton.setTitle("add_new_card".localized(), for: .normal)
        addCardButton.ecoDelegate = self
        addCardButton.translatesAutoresizingMaskIntoConstraints = false
        addCardButton.setEnabled(true) // Always enabled (single state)
        
        // Setup Card Text Field
        setupCardTextField()
        
        // Setup constraints for button
        setupButtonConstraints()
    }
    
    private func setupCardTextField() {
        let cardTextField = STPPaymentCardTextField()
        cardTextField.translatesAutoresizingMaskIntoConstraints = false
        cardTextField.isUserInteractionEnabled = true
        // Do not observe changes continuously
        cardTextField.delegate = nil
        
        // Do not customize Stripe SDK properties - let SDK handle appearance internally
        // Setting color properties can cause crashes if types don't match SDK expectations
        // (e.g., borderColor expects CGColor, not UIColor)
        
        self.cardTextField = cardTextField
    }
    
    private func setupButtonConstraints() {
        view.addSubview(addCardButton)
        
        NSLayoutConstraint.activate([
            addCardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addCardButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addCardButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            addCardButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - UI Updates
    
    private func updateNavigationTitle(_ title: String) {
        if let navBarController = navigationBarViewController?.controller as? DefaultEcoNavigationBarController {
            var state = navBarController.state.value
            state.title = title
            navBarController.state.value = state
        }
    }
    
    // MARK: - Actions
    
    private func handleAddNewCard() {
        guard let cardTextField = cardTextField else { return }
        
        // Validate card fields manually (not using Stripe SDK's isValid)
        let cardNumber = cardTextField.cardNumber ?? ""
        let hasCardNumber = !cardNumber.isEmpty && cardNumber.count >= 13
        let hasExpiry = cardTextField.expirationMonth > 0 && cardTextField.expirationYear > 0
        let hasCVC = !(cardTextField.cvc ?? "").isEmpty && (cardTextField.cvc ?? "").count >= 3
        
        guard hasCardNumber && hasExpiry && hasCVC else {
            showAlert(title: "Invalid Card", message: "Please enter a valid card number, expiry date, and CVC")
            return
        }
        
        // Create payment method with Stripe
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = cardTextField.cardNumber
        cardParams.expMonth = NSNumber(value: cardTextField.expirationMonth)
        cardParams.expYear = NSNumber(value: cardTextField.expirationYear)
        cardParams.cvc = cardTextField.cvc
        
        let paymentMethodParams = STPPaymentMethodParams(card: cardParams, billingDetails: nil, metadata: nil)
        
        STPAPIClient.shared.createPaymentMethod(with: paymentMethodParams) { [weak self] paymentMethod, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.showAlert(title: "error".localized(), message: error.localizedDescription)
                    return
                }
                
                guard let paymentMethod = paymentMethod else {
                    self.showAlert(title: "error".localized(), message: "failed_to_create_payment_method".localized())
                    return
                }
                
                // Save payment method to backend
                if let controller = self.paymentCardController as? DefaultPaymentCardController {
                    controller.didSavePaymentMethod(paymentMethodId: paymentMethod.stripeId)
                    // Reset selection will be handled in controller's didSavePaymentMethod completion
                }
                
                // Clear card input
                self.cardTextField?.clear()
            }
        }
    }
    
    private func handleDeleteCard(at index: Int) {
        let alert = UIAlertController(
            title: "delete_card".localized(),
            message: "delete_card_confirm".localized(),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "cancel".localized(), style: .cancel))
        alert.addAction(UIAlertAction(title: "ok".localized(), style: .destructive) { [weak self] _ in
            self?.paymentCardController.didTapDeleteCard(at: index)
        })
        
        present(alert, animated: true)
    }
    
    private func showSuccessAlert(message: String) {
        paymentCardController.successMessage.value = nil
        showAlert(
            title: "success".localized(),
            message: message
        )
    }
}

// MARK: - UITableViewDataSource

extension PaymentCardViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1 // Card input cell
        case 1:
            return paymentCardController.paymentCards.value.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            return createCardInputCell(for: tableView, at: indexPath)
        case 1:
            return createSavedCardCell(for: tableView, at: indexPath)
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Add new card"
        case 1:
            return "Card saved"
        default:
            return nil
        }
    }
    
    private func createCardInputCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CardInputCell", for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .systemBackground
        
        // Remove existing subviews
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Add card text field
        if let cardTextField = cardTextField {
            cell.contentView.addSubview(cardTextField)
            cardTextField.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                cardTextField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
                cardTextField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
                cardTextField.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 16),
                cardTextField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -16),
                cardTextField.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
        
        cardTextFieldCell = cell
        return cell
    }
    
    private func createSavedCardCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SavedCardCell", for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .systemBackground
        
        // Remove existing subviews
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let paymentCard = paymentCardController.paymentCards.value[indexPath.row]
        
        // Create container stack view
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Card icon image view
        let cardIconImageView = UIImageView()
        cardIconImageView.image = UIImage(named: paymentCard.cardIconName)
        cardIconImageView.contentMode = .scaleAspectFit
        cardIconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardIconImageView.widthAnchor.constraint(equalToConstant: 40),
            cardIconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Card info label với "default" in nghiêng nếu isDefault
        let cardInfoLabel = UILabel()

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.label
        ]

        let attributedText = NSMutableAttributedString(
            string: paymentCard.displayName,
            attributes: baseAttributes
        )

        if paymentCard.isDefault {
            let defaultText = NSAttributedString(
                string: " default",
                attributes: [
                    .font: UIFont.italicSystemFont(ofSize: 14),
                    .foregroundColor: Colors.tokenRainbowBlueEnd
                ]
            )
            attributedText.append(defaultText)
        }

        cardInfoLabel.attributedText = attributedText
        
        // Delete label with tap gesture
        let deleteLabel = UILabel()
        deleteLabel.text = "delete".localized()
        deleteLabel.font = UIFont.italicSystemFont(ofSize: 14)
        deleteLabel.textColor = Colors.tokenRainbowBlueEnd
        deleteLabel.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDeleteLabelTap(_:)))
        deleteLabel.addGestureRecognizer(tapGesture)
        deleteLabel.tag = indexPath.row // Store index in tag
        
        // Add to stack view
        stackView.addArrangedSubview(cardIconImageView)
        stackView.addArrangedSubview(cardInfoLabel)
        stackView.addArrangedSubview(UIView()) // Spacer
        stackView.addArrangedSubview(deleteLabel)
        
        // Add stack view to cell
        cell.contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
            stackView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12)
        ])
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension PaymentCardViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 76 // 16 + 44 + 16
        case 1:
            return 60
        default:
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Only show separator for section 1
        if indexPath.section == 0 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
        } else {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        }
    }
    
}

// MARK: - EcoButtonDelegate

extension PaymentCardViewController: EcoButtonDelegate {
    
    func buttonDidTap(_ button: EcoButton) {
        handleAddNewCard()
    }
}

// MARK: - Actions

extension PaymentCardViewController {
    
    @objc private func handleDeleteLabelTap(_ gesture: UITapGestureRecognizer) {
        guard let deleteLabel = gesture.view as? UILabel else { return }
        let index = deleteLabel.tag
        handleDeleteCard(at: index)
    }
}

