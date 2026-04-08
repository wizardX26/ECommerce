//
//  PaymentMethodViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 15/1/26.
//

import UIKit
import StripePaymentSheet
import Stripe
import StripePayments
import LocalAuthentication

final class PaymentMethodViewController: EcoViewController, STPAuthenticationContext {
    
    // MARK: - STPAuthenticationContext
    
    /// Trả về view controller để Stripe present authentication UI (3D Secure, Face ID, OTP, etc.)
    /// 
    /// **Cách hoạt động:**
    /// 1. Khi `STPPaymentHandler.confirmPayment()` được gọi, Stripe SDK sẽ:
    ///    - Confirm payment với Stripe API
    ///    - Nếu payment cần 3D Secure authentication, Stripe sẽ trả về `requires_action`
    ///    - Stripe SDK tự động gọi `authenticationPresentingViewController()` để lấy view controller
    ///    - Stripe SDK tự động present authentication UI (modal/webview) trên view controller này
    ///    - User hoàn tất authentication (nhập OTP, Face ID, etc.)
    ///    - Stripe SDK tự động xử lý và gọi completion callback với kết quả
    ///
    /// 2. **3D Secure Flow:**
    ///    - Stripe SDK sẽ hiển thị webview với authentication form từ bank
    ///    - User nhập OTP hoặc thực hiện authentication
    ///    - Sau khi authentication thành công, payment sẽ được confirm
    ///    - Completion callback sẽ được gọi với status `.succeeded`
    ///
    /// 3. **Face ID / Touch ID:**
    ///    - Nếu bank yêu cầu biometric authentication, Stripe SDK sẽ tự động hiển thị
    ///    - User xác thực bằng Face ID/Touch ID
    ///    - Sau khi xác thực thành công, payment sẽ được confirm
    ///
    /// **Lưu ý:** View controller này phải đang visible (trong view hierarchy) để Stripe có thể present UI
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }
    
    // MARK: - UI Components
    
    private let progressIndicator = CheckoutProgressIndicator()
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.backgroundColor = .systemBackground
        tv.separatorStyle = .singleLine
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let orderActionView = OrderActionView()
    
    // Checkbox để set default card
    private var shouldSetDefaultCard: Bool = false
    
    var paymentMethodController: PaymentMethodController! {
        get { controller as? PaymentMethodController }
    }
    
    private var paymentSheet: PaymentSheet?
    
    // MARK: - Lifecycle
    
    static func create(
        with paymentMethodController: PaymentMethodController
    ) -> PaymentMethodViewController {
        let view = PaymentMethodViewController.instantiateViewController()
        view.controller = paymentMethodController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Ẩn TabBar ngay từ viewDidLoad để đảm bảo ẩn khi mở lần đầu
        self.tabBarController?.tabBar.isHidden = true
        isSwipeBackEnabled = true // Cho phép swipe back
        setupViews()
        bindObservables()
        paymentMethodController.didLoadView()
        
        // Setup callback to show PaymentSheet when payment intent is created (for add new card)
        if let defaultController = paymentMethodController as? DefaultPaymentMethodController {
            defaultController.onShowPaymentSheet = { [weak self] in
                self?.showPaymentSheetIfReady()
            }
            
            // Setup callback to remove items from cart after successful payment
            defaultController.onPaymentSuccess = { [weak self] in
                self?.handlePaymentSuccess()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ẩn TabBar khi vào màn hình PaymentMethod (đảm bảo ẩn khi quay lại)
        self.tabBarController?.tabBar.isHidden = true
        paymentMethodController.onViewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Hiện TabBar khi rời màn hình PaymentMethod
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Không trigger Face ID ở đây nữa
        // Face ID sẽ được gọi khi user bấm "Pay" trong PaymentSheet
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        // Progress Indicator
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressIndicator)
        
        // Setup TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PaymentCardCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AddCardCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SetDefaultCardCell")
        
        view.addSubview(tableView)
        view.addSubview(orderActionView)
        
        orderActionView.delegate = self
        orderActionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup OrderActionView để hiển thị đẹp - chỉ hiển thị button, không có top row và left item
        orderActionView.topLeftLabelText = nil
        orderActionView.topRightLabelText = nil
        orderActionView.leftItemType = .none
        
        NSLayoutConstraint.activate([
            // Progress Indicator
            progressIndicator.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 88),
            progressIndicator.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // TableView
            tableView.topAnchor.constraint(equalTo: progressIndicator.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: orderActionView.topAnchor),
            
            // OrderActionView
            orderActionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            orderActionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            orderActionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            orderActionView.heightAnchor.constraint(equalToConstant: 116) // Increased by 64pt (52 + 64 = 116)
        ])
        
        // Điều chỉnh OrderActionView để hiển thị đẹp với chiều cao 52pt
        adjustOrderActionViewForCompactHeight()
        
        // Set progress indicator ở bước 2 "Confirm Payment"
        progressIndicator.updateProgress(to: .confirmPayment)
        
        updateOrderActionView()
    }
    
    private func adjustOrderActionViewForCompactHeight() {
        // Điều chỉnh OrderActionView để hiển thị đẹp với chiều cao 52pt
        // Tìm và điều chỉnh constraints của OrderActionView để giảm padding
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Tìm containerStackView trong OrderActionView
            for subview in self.orderActionView.subviews {
                if let stackView = subview as? UIStackView {
                    // Điều chỉnh constraints của stackView
                    for constraint in self.orderActionView.constraints {
                        if (constraint.firstItem === stackView || constraint.secondItem === stackView) {
                            // Giảm top padding từ 12pt xuống 0pt
                            if constraint.firstAttribute == .top && constraint.constant == Spacing.tokenSpacing12 {
                                constraint.constant = 0
                            }
                            // Giảm bottom padding từ -12pt xuống 0pt
                            if constraint.firstAttribute == .bottom && constraint.constant == -Spacing.tokenSpacing12 {
                                constraint.constant = 0
                            }
                        }
                    }
                }
            }
            
            // Điều chỉnh button height từ 56pt xuống 52pt
            self.findAndAdjustButtonHeight(in: self.orderActionView)
        }
    }
    
    private func findAndAdjustButtonHeight(in view: UIView) {
        for subview in view.subviews {
            if let button = subview as? EcoButton {
                // Điều chỉnh button height constraint
                for constraint in button.constraints {
                    if constraint.firstAttribute == .height && constraint.constant == Sizing.tokenSizing56 {
                        constraint.constant = 52
                    }
                }
                // Tìm constraints từ parent
                if let parentView = button.superview {
                    for constraint in parentView.constraints {
                        if (constraint.firstItem === button || constraint.secondItem === button) &&
                            constraint.firstAttribute == .height && constraint.constant == Sizing.tokenSizing56 {
                            constraint.constant = 52
                        }
                    }
                }
            } else {
                // Recursive search
                findAndAdjustButtonHeight(in: subview)
            }
        }
    }
    
    private func bindObservables() {
        paymentMethodController.paymentCards.observe(on: self) { [weak self] _ in
            self?.tableView.reloadData()
            self?.updateOrderActionView()
        }
        
        paymentMethodController.selectedCard.observe(on: self) { [weak self] _ in
            self?.tableView.reloadData()
            self?.updateOrderActionView()
            self?.reloadSetDefaultCardCell()
        }
        
        paymentMethodController.loading.observe(on: self) { [weak self] isLoading in
            self?.orderActionView.isLoading = isLoading
        }
        
        paymentMethodController.error.observe(on: self) { [weak self] error in
            guard let error = error else { return }
            self?.showAlert(title: "error".localized(), message: error.localizedDescription)
        }
    }
    
    override func applyNavigation(_ state: EcoNavigationState) {
        super.applyNavigation(state)
        // Override left item tap callback để pop back về trước
        // Lưu ý: Cần theo dõi flag openFromSideMenu trong MainContainerViewController
        // để không kích hoạt mở sidemenu khi swipeBack
        DispatchQueue.main.async { [weak self] in
            if let navBarController = self?.navigationBarViewController?.controller as? DefaultEcoNavigationBarController {
                navBarController.onLeftItemTap = { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    private func updateOrderActionView() {
        let hasSelectedCard = paymentMethodController.selectedCard.value != nil
        orderActionView.buttonTitle = "pay".localized()
        orderActionView.isButtonEnabled = hasSelectedCard
        orderActionView.leftItemType = .none
    }
    
    private func reloadSetDefaultCardCell() {
        let cards = paymentMethodController.paymentCards.value
        if cards.count > 0 {
            let indexPath = IndexPath(row: cards.count, section: 0)
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    // MARK: - Payment Sheet (chỉ dùng cho Add new card)
    
    private func showPaymentSheetIfReady() {
        guard let defaultController = paymentMethodController as? DefaultPaymentMethodController else { return }
        
        // Lấy customerId và ephemeralKey để setup configuration
        defaultController.getPaymentInfo { [weak self] _, customerId, ephemeralKey in
            guard let self = self else { return }
            
            // Chỉ dùng PaymentSheet cho Add new card
            self.preparePaymentSheetForAddCard(customerId: customerId, ephemeralKey: ephemeralKey)
        }
    }
    
    private func preparePaymentSheetForAddCard(customerId: String?, ephemeralKey: String?) {
        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "My Shop"
        
        // Chỉ set customer nếu có customerId và ephemeralKey
        if let customerId = customerId, let ephemeralKey = ephemeralKey {
            configuration.customer = .init(
                id: customerId,
                ephemeralKeySecret: ephemeralKey
            )
        }
        
        configuration.allowsDelayedPaymentMethods = false
        
        // Thêm returnURL
        if let bundleId = Bundle.main.bundleIdentifier {
            configuration.returnURL = "\(bundleId)://stripe-redirect"
        }
        
        // Lấy order từ controller để lấy amount
        guard let defaultController = paymentMethodController as? DefaultPaymentMethodController else {
            return
        }
        
        let totalAmount = defaultController.getOrderTotalAmount()
        let amount = Int(totalAmount)  // VND: amount trực tiếp
        
        // Tạo IntentConfiguration cho Add new card
        let intentConfig = PaymentSheet.IntentConfiguration(
            mode: .payment(
                amount: amount,
                currency: "vnd"
            )
        ) { [weak self] paymentMethod, shouldSavePaymentMethod, completion in
            guard let self = self else {
                completion(.failure(NSError(domain: "PaymentMethodViewController", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewController deallocated"])))
                return
            }
            
            // Add new card: Face ID → Backend → Stripe
            self.handleConfirmForAddCard(
                paymentMethod: paymentMethod,
                shouldSavePaymentMethod: shouldSavePaymentMethod,
                completion: completion
            )
        }
        
        paymentSheet = PaymentSheet(
            intentConfiguration: intentConfig,
            configuration: configuration
        )
        
        paymentSheet?.present(from: self) { [weak self] result in
            guard let self = self else { return }
            self.handlePaymentSheetResult(result)
        }
    }
    
    private func handlePaymentSheetResult(_ result: PaymentSheetResult) {
        switch result {
        case .completed:
            // Payment completed successfully (cho Add new card)
            // Confirm payment với backend
            confirmPaymentWithBackend()
            
        case .canceled: break
            // User canceled
            
        case .failed(let error):
            // Payment failed
            if let underlyingError = (error as NSError).userInfo[NSUnderlyingErrorKey] as? NSError {
            }
            
            let errorMessage = error.localizedDescription.isEmpty ? 
                "There was an unexpected error. Please try again." : 
                error.localizedDescription
            showAlert(title: "Payment Failed", message: errorMessage)
        }
    }
    
    private func handleConfirmForAddCard(
        paymentMethod: STPPaymentMethod,
        shouldSavePaymentMethod: Bool,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Face ID → Backend → Stripe (cho Add new card)
        authenticateBeforePayment { [weak self] success in
            guard let self = self else {
                completion(.failure(NSError(domain: "PaymentAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "ViewController deallocated"])))
                return
            }
            
            guard success else {
                completion(.failure(NSError(domain: "PaymentAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Authentication failed or cancelled"])))
                return
            }
            
            // ⚠️ QUAN TRỌNG: Khi add thẻ mới, KHÔNG gửi payment_method_id
            // Vì payment method mới chưa được attach vào customer
            // Backend sẽ tạo payment intent không có payment_method_id
            // PaymentSheet sẽ tự động attach payment method vào customer khi confirm
            self.createPaymentIntentForNewCard(
                shouldSavePaymentMethod: shouldSavePaymentMethod,
                completion: completion
            )
        }
    }
    
    /// Tạo payment intent cho thẻ mới (KHÔNG có payment_method_id)
    private func createPaymentIntentForNewCard(
        shouldSavePaymentMethod: Bool,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let defaultController = paymentMethodController as? DefaultPaymentMethodController else {
            completion(.failure(NSError(domain: "PaymentMethod", code: -1, userInfo: [NSLocalizedDescriptionKey: "Controller not found"])))
            return
        }
        
        // Tạo payment intent KHÔNG có payment_method_id
        defaultController.createPaymentIntentWithoutMethod { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let paymentIntent):
                completion(.success(paymentIntent.clientSecret))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Tạo payment intent với saved payment method (có payment_method_id)
    private func createAndConfirmPaymentIntent(
        paymentMethodId: String,
        shouldSavePaymentMethod: Bool,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let defaultController = paymentMethodController as? DefaultPaymentMethodController else {
            completion(.failure(NSError(domain: "PaymentMethod", code: -1, userInfo: [NSLocalizedDescriptionKey: "Controller not found"])))
            return
        }
        
        defaultController.createPaymentIntentWithMethod(
            paymentMethodId: paymentMethodId
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let paymentIntent):
                completion(.success(paymentIntent.clientSecret))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func handlePaymentSuccess() {
        // Update progress indicator to show success
        progressIndicator.setSuccessStepCompleted()
        
        // Remove purchased items from cart
        if let defaultController = paymentMethodController as? DefaultPaymentMethodController {
            let productIds = defaultController.getPurchasedProductIds()
            if !productIds.isEmpty {
                let appDIContainer = AppDIContainer.shared
                let cartDIContainer = appDIContainer.makeCartSceneDIContainer()
                let cartController = cartDIContainer.makeCartController()
                cartController.didDeleteItems(productIds: productIds)
            }
        }
    }
    
    private func showSuccessAlert() {
        let alert = UIAlertController(
            title: "success".localized(),
            message: "payment_completed_success".localized(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "ok".localized(), style: .default) { [weak self] _ in
            // Navigate back or to success screen
            self?.navigationController?.popToRootViewController(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func showAddCardPaymentSheet() {
        // Trigger controller to create setup payment intent
        // Controller will call onPaymentSuccess callback when ready
        paymentMethodController.didTapAddNewCard()
    }
    
    private func notifyBackendSuccess() {
        guard let defaultController = paymentMethodController as? DefaultPaymentMethodController,
              let paymentIntentId = defaultController.getPaymentIntentId() else {
            return
        }
        
        // Payment is already confirmed by Stripe SDK
        // Navigate to success screen
        // TODO: Navigate to success screen
    }
    
    // MARK: - Biometric Authentication with Passcode Fallback
    
    /// Trigger xin quyền Face ID ngay khi màn hình xuất hiện
    /// Điều này giúp app xin quyền sớm, không cần đợi đến khi user nhấn Pay
    private func requestFaceIDPermissionIfNeeded() {
        let context = LAContext()
        var error: NSError?
        
        // Kiểm tra xem thiết bị có hỗ trợ authentication không
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            if let error = error {
            }
            return
        }
        
        // Xác định loại sinh trắc học
        let biometricType = context.biometricType
        let reason: String
        
        switch biometricType {
        case .faceID:
            reason = "Xác thực Face ID để bảo mật thanh toán"
        case .touchID:
            reason = "Xác thực Touch ID để bảo mật thanh toán"
        case .none:
            // Không có Face ID/Touch ID, sẽ dùng Passcode
            reason = "Xác thực để bảo mật thanh toán"
        }
        
        // Trigger xin quyền bằng cách gọi evaluatePolicy
        // Lần đầu tiên sẽ hiển thị alert xin quyền
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                } else {
                    if let error = error {
                        if let laError = error as? LAError {
                            switch laError.code {
//                            case .userCancel:
//                            case .userFallback:
//                            case .biometryNotAvailable:
//                            case .biometryNotEnrolled:
//                            case .biometryLockout:
                            default: break
                            }
                        } else {
                        }
                    }
                }
            }
        }
    }
    
    private func authenticateBeforePayment(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        // Sử dụng .deviceOwnerAuthentication để tự động fallback sang Passcode
        // Nếu thiết bị có Face ID/Touch ID, sẽ hiển thị Face ID/Touch ID trước
        // Nếu Face ID/Touch ID thất bại hoặc không có, sẽ tự động hiển thị Passcode (giống unlock thiết bị)
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            showAuthenticationPrompt(context: context, completion: completion)
        } else {
            // Thiết bị không hỗ trợ authentication
            if let error = error {
            }
            completion(false)
        }
    }
    
    private func showAuthenticationPrompt(context: LAContext, completion: @escaping (Bool) -> Void) {
        // Xác định loại sinh trắc học để hiển thị message phù hợp
        let biometricType = context.biometricType
        let reason: String
        
        switch biometricType {
        case .faceID:
            reason = "Xác nhận danh tính để hoàn tất thanh toán"
        case .touchID:
            reason = "Xác nhận danh tính để hoàn tất thanh toán"
        case .none:
            reason = "Xác nhận danh tính để hoàn tất thanh toán"
        }
        
        // Sử dụng .deviceOwnerAuthentication thay vì .deviceOwnerAuthenticationWithBiometrics
        // Điều này cho phép tự động fallback sang Passcode nếu Face ID/Touch ID thất bại
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: reason
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(true)
                } else {
                    if let error = error {
                        // Kiểm tra nếu user cancel
                        if let laError = error as? LAError {
                            switch laError.code {
                            case .userCancel: break
                            case .userFallback: break
                            default:
                                break
                            }
                        }
                    }
                    completion(false)
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource

extension PaymentMethodViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Section 0: Recent Card, Section 1: Add new card
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            // Section 0: Recent Card + Set default checkbox
            let cardCount = paymentMethodController.paymentCards.value.count
            return cardCount > 0 ? cardCount + 1 : 0 // +1 for "Set default" checkbox
        case 1:
            // Section 1: Add new card
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cards = paymentMethodController.paymentCards.value
            
            if indexPath.row < cards.count {
                // Saved card cell
                return createSavedCardCell(for: tableView, at: indexPath, card: cards[indexPath.row])
            } else {
                // Set default card checkbox cell
                return createSetDefaultCardCell(for: tableView, at: indexPath)
            }
            
        case 1:
            // Add new card cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddCardCell", for: indexPath)
            cell.textLabel?.text = "Add new card"
            cell.textLabel?.font = Typography.fontBold16
            cell.textLabel?.textColor = Colors.tokenBrown
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Recent Card"
        case 1:
            return "Add new card"
        default:
            return nil
        }
    }
    
    private func createSavedCardCell(for tableView: UITableView, at indexPath: IndexPath, card: PaymentCard) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentCardCell", for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .systemBackground
        
        // Remove existing subviews
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        let isSelected = paymentMethodController.selectedCard.value?.id == card.id
        
        // Create container stack view
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Card icon image view
        let cardIconImageView = UIImageView()
        cardIconImageView.image = UIImage(named: card.cardIconName)
        cardIconImageView.contentMode = .scaleAspectFit
        cardIconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardIconImageView.widthAnchor.constraint(equalToConstant: 40),
            cardIconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Card info label với "default" in nghiêng nếu isDefault
        let cardInfoLabel = UILabel()
        let cardText = card.displayName

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: Typography.fontRegular16,
            .foregroundColor: UIColor.label
        ]

        let attributedText = NSMutableAttributedString(
            string: cardText,
            attributes: baseAttributes
        )

        if card.isDefault {
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
        // Checkmark icon (nếu selected)
        let checkmarkImageView = UIImageView()
        if isSelected {
            checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
            checkmarkImageView.tintColor = Colors.tokenRainbowBlueEnd
        } else {
            checkmarkImageView.image = UIImage(systemName: "circle")
            checkmarkImageView.tintColor = Colors.tokenDark20
        }
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        // Add to stack view
        stackView.addArrangedSubview(cardIconImageView)
        stackView.addArrangedSubview(cardInfoLabel)
        stackView.addArrangedSubview(UIView()) // Spacer
        stackView.addArrangedSubview(checkmarkImageView)
        
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
    
    private func createSetDefaultCardCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SetDefaultCardCell", for: indexPath)
        cell.selectionStyle = .none
        cell.backgroundColor = .systemBackground
        
        // Remove existing subviews
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Create checkbox với label
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let checkbox = UIButton(type: .system)
        checkbox.setImage(UIImage(systemName: shouldSetDefaultCard ? "checkmark.square.fill" : "square"), for: .normal)
        checkbox.tintColor = shouldSetDefaultCard ? Colors.tokenRainbowBlueEnd : Colors.tokenDark60
        checkbox.addTarget(self, action: #selector(toggleSetDefaultCard), for: .touchUpInside)
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            checkbox.widthAnchor.constraint(equalToConstant: 24),
            checkbox.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        let label = UILabel()
        label.text = "Set default card for pay later"
        label.font = Typography.fontRegular14
        label.textColor = Colors.tokenDark100
        
        stackView.addArrangedSubview(checkbox)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(UIView()) // Spacer
        
        cell.contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
        ])
        
        return cell
    }
    
    @objc private func toggleSetDefaultCard(_ sender: UIButton) {
        shouldSetDefaultCard.toggle()
        sender.setImage(UIImage(systemName: shouldSetDefaultCard ? "checkmark.square.fill" : "square"), for: .normal)
        sender.tintColor = shouldSetDefaultCard ? Colors.tokenRainbowBlueEnd : Colors.tokenDark60
    }
}

// MARK: - UITableViewDelegate

extension PaymentMethodViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            let cards = paymentMethodController.paymentCards.value
            if indexPath.row < cards.count {
                // Select card
                let card = cards[indexPath.row]
                paymentMethodController.didSelectCard(card)
            } else {
                // Toggle set default checkbox
                shouldSetDefaultCard.toggle()
                tableView.reloadRows(at: [indexPath], with: .none)
            }
            
        case 1:
            // Add new card - show PaymentSheet
            showAddCardPaymentSheet()
            
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            let cards = paymentMethodController.paymentCards.value
            if indexPath.row < cards.count {
                return 60 // Card cell
            } else {
                return 44 // Set default checkbox cell
            }
        case 1:
            return 44 // Add new card cell
        default:
            return 44
        }
    }
}

// MARK: - OrderActionViewDelegate

extension PaymentMethodViewController: OrderActionViewDelegate {
    
    func orderActionViewDidTapAction(_ view: OrderActionView) {
        // Kiểm tra user đã chọn thẻ chưa
        guard let selectedCard = paymentMethodController.selectedCard.value else {
            showAlert(title: "error".localized(), message: "please_select_payment_method".localized())
            return
        }
        
        // Bước 1: Verify Face ID/Touch ID với fallback Passcode
        authenticateBeforePayment { [weak self] success in
            guard let self = self else { return }
            
            guard success else {
                // Xác thực thất bại hoặc user cancel
                return
            }
            
            // Bước 2: Xác thực thành công, xử lý thanh toán
            self.processPayment(with: selectedCard)
        }
    }
    
    private func processPayment(with card: PaymentCard) {
        guard let defaultController = paymentMethodController as? DefaultPaymentMethodController else {
            showAlert(title: "error".localized(), message: "controller_not_found".localized())
            return
        }
        
        // Set default card song song (nếu user chọn)
        if shouldSetDefaultCard {
            defaultController.setDefaultCard(paymentMethodId: card.id) { [weak self] success in
                if success {
                } else {
                }
            }
        }
        
        // Gọi API create-payment-intent với payment_method_id
        defaultController.createPaymentIntentWithMethod(
            paymentMethodId: card.id
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let paymentIntent):
                // Backend đã tạo payment intent thành công
                // Dùng STPPaymentHandler để confirm payment (lần DUY NHẤT dùng StripeSDK)
                // Pass cả paymentMethodId để Stripe SDK biết dùng payment method nào
                self.confirmPaymentWithStripeHandler(
                    clientSecret: paymentIntent.clientSecret,
                    paymentMethodId: card.id
                )
                
            case .failure(let error):
                // Kiểm tra nếu có modal đang present thì đợi dismiss
                if self.presentedViewController != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.showAlert(title: "error".localized(), message: "failed_to_create_payment_intent".localized() + ": \(error.localizedDescription)")
                    }
                } else {
                    self.showAlert(title: "error".localized(), message: "failed_to_create_payment_intent".localized() + ": \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func confirmPaymentWithStripeHandler(clientSecret: String, paymentMethodId: String) {
        // Đây là lần DUY NHẤT dùng StripeSDK
        let paymentIntentParams = STPPaymentIntentParams(clientSecret: clientSecret)
        
        // ⚠️ QUAN TRỌNG: Set paymentMethodId vào params để Stripe SDK biết dùng saved payment method nào
        // Mặc dù backend đã tạo payment intent với payment_method_id, nhưng Stripe SDK cần biết
        // payment method ID khi confirm để xử lý đúng (đặc biệt là 3D Secure)
        paymentIntentParams.paymentMethodId = paymentMethodId
        
        
        // STPPaymentHandler sẽ tự động xử lý:
        // 1. Confirm payment với Stripe API
        // 2. Nếu cần 3D Secure, sẽ present authentication UI tự động qua STPAuthenticationContext
        // 3. Gọi completion callback với kết quả
        STPPaymentHandler.shared().confirmPayment(
            paymentIntentParams,
            with: self  // self conforms STPAuthenticationContext để Stripe present 3D Secure UI
        ) { [weak self] status, paymentIntent, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch status {
                case .succeeded:
                    // Stripe SDK đã confirm payment thành công (có thể đã xử lý 3D Secure nếu cần)
                    // Bây giờ confirm với backend để cập nhật order status
                    self.confirmPaymentWithBackend()
                    
                case .failed:
                    if let error = error {
                        let nsError = error as NSError
                        if let userInfo = nsError.userInfo as? [String: Any] {
                            
                            // Kiểm tra nếu là lỗi confirmation_method: manual
                            if let errorMessage = userInfo["com.stripe.lib:ErrorMessageKey"] as? String {
                                if errorMessage.contains("confirmation_method") && errorMessage.contains("manual") {
                                }
                            }
                        }
                    }
                    // Đợi một chút để Stripe dismiss modal trước khi hiển thị alert
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        var errorMessage = error?.localizedDescription ?? "Payment failed"
                        // Thêm thông tin chi tiết nếu là lỗi confirmation_method
                        if let nsError = error as? NSError,
                           let userInfo = nsError.userInfo as? [String: Any],
                           let stripeError = userInfo["com.stripe.lib:ErrorMessageKey"] as? String,
                           stripeError.contains("confirmation_method") {
                            errorMessage = "Backend configuration error: PaymentIntent must use 'automatic' confirmation_method. Please contact support."
                        }
                        self.showAlert(title: "payment_failed".localized(), message: errorMessage)
                    }
                    
                case .canceled: break
                    
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func confirmPaymentWithBackend() {
        guard let defaultController = paymentMethodController as? DefaultPaymentMethodController,
              let paymentIntentId = defaultController.getPaymentIntentId() else {
            showAlert(title: "error".localized(), message: "payment_intent_id_not_found".localized())
            return
        }
        
        // Call confirm payment API
        defaultController.confirmPayment(paymentIntentId: paymentIntentId) { [weak self] success in
            if success {
                // Handle payment success (remove items from cart)
                self?.handlePaymentSuccess()
                // Show success message
                self?.showSuccessAlert()
            } else {
                self?.showAlert(title: "error".localized(), message: "failed_to_confirm_payment".localized())
            }
        }
    }
}
    
    func orderActionViewDidTapLeftItem(_ view: OrderActionView) {
        // No action needed
    }

