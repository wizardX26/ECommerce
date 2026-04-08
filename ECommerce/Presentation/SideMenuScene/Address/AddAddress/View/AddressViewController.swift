//
//  AddressViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import UIKit

final class AddressViewController: EcoViewController {
    
    // MARK: - UI Components
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Form Fields
    private let contactPersonNameLabel = UILabel()
    private let contactPersonNameTextField = EcoTextField()
    
    private let contactPersonNumberLabel = UILabel()
    private let contactPersonNumberTextField = EcoTextField()
    
    private let addressDetailLabel = UILabel()
    private let addressDetailTextField = EcoTextField()
    
    // Location Pickers
    private let countryLabel = UILabel()
    private let countryPickerButton = UIButton(type: .system)
    
    private let provinceLabel = UILabel()
    private let provincePickerButton = UIButton(type: .system)
    
    private let districtLabel = UILabel()
    private let districtPickerButton = UIButton(type: .system)
    
    private let wardLabel = UILabel()
    private let wardPickerButton = UIButton(type: .system)
    
    private let addressTypeLabel = UILabel()
    private let addressTypeSegmentedControl = UISegmentedControl(items: ["Shipping", "Shop", "Other"])
    
    private let defaultAddressStack = UIStackView()
    private let defaultAddressCheckbox = UIImageView()
    private let defaultAddressLabel = UILabel()
    private var isCheckboxSelected: Bool = false
    
    private var saveButton: EcoButton!
    
    private var addressController: AddressController! {
        get { controller as? AddressController }
    }
    
    // Store reference to CardViewController to prevent opening multiple times
    private var cardViewController: CardViewController?
    
    // Selected location IDs
    private var selectedCountryId: Int = 1 // Default: Việt Nam
    private var selectedProvinceId: Int = 2 // Default: Hà Nội
    private var selectedDistrictId: Int = 0
    private var selectedWardId: Int = 0
    
    // Lưu address type
    private var selectedAddressType: String = "shipping" // Default: "shipping"
    
    // MARK: - Lifecycle
    
    static func create(
        with addressController: AddressController
    ) -> AddressViewController {
        let view = AddressViewController.instantiateViewController()
        view.controller = addressController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isSwipeBackEnabled = true
        setupViews()
        setupFormFields() // Must be called before bindAddressSpecific() to initialize saveButton
        bindAddressSpecific()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let navBarView = navigationBarViewController?.view {
            view.bringSubviewToFront(navBarView)
            navBarView.isUserInteractionEnabled = true
        }
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindAddressSpecific()
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
        
        // Setup right bar button callback in controller - action from .icon() will call this
        if let defaultController = addressController as? DefaultAddressController {
            defaultController.onRightBarButtonTap = { [weak self] in
                self?.showLocationList()
            }
        }
    }
    
    // MARK: - Address-Specific Binding
    
    private func bindAddressSpecific() {
        addressController.isSaveSuccess.observe(on: self) { [weak self] isSuccess in
            if isSuccess {
                // Success state is handled via successMessage Observable
            }
        }
        
        addressController.successMessage.observe(on: self) { [weak self] message in
            guard let message = message, !message.isEmpty else { return }
            self?.showSuccessAlert(message: message)
        }
        
        addressController.error.observe(on: self) { [weak self] error in
            guard let self = self, let error = error else { return }
            self.showAlert(title: "Error", message: error.localizedDescription)
        }
        
        addressController.loading.observe(on: self) { [weak self] isLoading in
            guard let self = self, let saveButton = self.saveButton else { return }
            saveButton.setLoading(isLoading)
        }
        
        // Setup address type segmented control
        addressTypeSegmentedControl.selectedSegmentIndex = 0 // Default: Shipping
        addressTypeSegmentedControl.addTarget(self, action: #selector(addressTypeChanged), for: .valueChanged)
    }
    
    @objc private func addressTypeChanged() {
        switch addressTypeSegmentedControl.selectedSegmentIndex {
        case 0:
            selectedAddressType = "shipping"
        case 1:
            selectedAddressType = "shop"
        case 2:
            selectedAddressType = "other"
        default:
            selectedAddressType = "shipping"
        }
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        title = addressController.screenTitle
        view.backgroundColor = .systemBackground
        
        // Scroll View
        scrollView.keyboardDismissMode = .onDrag
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        // Content View
        contentView.backgroundColor = .clear
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Constraints
        let navBarHeight = addressController.navigationBarInitialHeight - 52
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: navBarHeight),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupFormFields() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Spacing.tokenSpacing16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        // Contact Person Name
        setupField(
            label: contactPersonNameLabel,
            textField: contactPersonNameTextField,
            title: "contact_person_name".localized(),
            iconName: "person.fill",
            stackView: stackView
        )
        contactPersonNameTextField.placeholder = "contact_person_name".localized()
        
        // Contact Person Number
        setupField(
            label: contactPersonNumberLabel,
            textField: contactPersonNumberTextField,
            title: "contact_person_number".localized(),
            iconName: "phone.fill",
            stackView: stackView
        )
        contactPersonNumberTextField.placeholder = "contact_person_number".localized()
        contactPersonNumberTextField.keyboardType = .phonePad
        
        // Address Detail
        setupField(
            label: addressDetailLabel,
            textField: addressDetailTextField,
            title: "address_detail".localized(),
            iconName: "mappin.circle.fill",
            stackView: stackView
        )
        addressDetailTextField.placeholder = "address_detail_placeholder".localized()
        
        // Country Picker (disabled - cannot change)
        setupLocationPicker(
            label: countryLabel,
            button: countryPickerButton,
            title: "country".localized(),
            stackView: stackView,
            isEnabled: false
        )
        updateCountryButton()
        
        // Province Picker (disabled - cannot change)
        setupLocationPicker(
            label: provinceLabel,
            button: provincePickerButton,
            title: "province".localized(),
            stackView: stackView,
            isEnabled: false
        )
        updateProvinceButton()
        
        // District Picker
        setupLocationPicker(
            label: districtLabel,
            button: districtPickerButton,
            title: "district".localized(),
            stackView: stackView,
            isEnabled: true
        )
        updateDistrictButton()
        districtPickerButton.addTarget(self, action: #selector(districtTapped), for: .touchUpInside)
        
        // Ward Picker
        setupLocationPicker(
            label: wardLabel,
            button: wardPickerButton,
            title: "ward".localized(),
            stackView: stackView,
            isEnabled: true
        )
        updateWardButton()
        wardPickerButton.addTarget(self, action: #selector(wardTapped), for: .touchUpInside)
        
        // Address Type
        addressTypeLabel.text = "address_type".localized()
        addressTypeLabel.font = Typography.fontBold16
        addressTypeLabel.textColor = Colors.tokenDark100
        addressTypeLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(addressTypeLabel)
        
        addressTypeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(addressTypeSegmentedControl)
        
        // Default Address Checkbox
        setupDefaultAddressCheckbox(stackView: stackView)
        
        // Save Button - Use authButton style like Login
        saveButton = EcoButton.authButton(title: "save".localized())
        saveButton.ecoDelegate = self
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(saveButton)
        
        // Stack View Constraints
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.tokenSpacing22),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.tokenSpacing22),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.tokenSpacing22),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.tokenSpacing40),
            
            // Location Picker Buttons height
            countryPickerButton.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56),
            provincePickerButton.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56),
            districtPickerButton.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56),
            wardPickerButton.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56),
            addressTypeSegmentedControl.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing40),
            
            // Save Button height (same as Login)
            saveButton.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56)
        ])
    }
    
    private func setupField(
        label: UILabel,
        textField: EcoTextField,
        title: String,
        iconName: String,
        stackView: UIStackView
    ) {
        // Title Label (bold, above text field)
        label.text = title
        label.font = Typography.fontBold16
        label.textColor = Colors.tokenDark100
        label.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(label)
        
        // Text Field (styled like Login/SignUp)
        textField.type = .baseline
        textField.setLeftIcon(iconName, tintColor: Colors.tokenDark60)
        textField.cornerRadius = BorderRadius.tokenBorderRadius12
        textField.backgroundColorColor = Colors.tokenDark02
        textField.borderColor = Colors.tokenDark10
        textField.selectedBorderColor = Colors.tokenRainbowBlueEnd
        textField.errorBorderColor = Colors.tokenRed100
        textField.borderWidth = Sizing.tokenSizing01
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(textField)
        
        // Text Field height constraint
        NSLayoutConstraint.activate([
            textField.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56)
        ])
    }
    
    private func setupLocationPicker(
        label: UILabel,
        button: UIButton,
        title: String,
        stackView: UIStackView,
        isEnabled: Bool = true
    ) {
        label.text = title
        label.font = Typography.fontBold16
        label.textColor = Colors.tokenDark100
        label.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(label)
        
        // Create container view for button content
        let containerView = UIView()
        containerView.backgroundColor = Colors.tokenDark02
        containerView.layer.cornerRadius = BorderRadius.tokenBorderRadius12
        containerView.layer.borderWidth = Sizing.tokenSizing01
        containerView.layer.borderColor = Colors.tokenDark10.cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create title label
        let titleLabel = UILabel()
        titleLabel.font = Typography.fontRegular16
        titleLabel.textColor = isEnabled ? Colors.tokenDark100 : Colors.tokenDark60
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.tag = 999 // Tag to identify for updates
        
        // Create chevron image view
        let chevronImageView = UIImageView()
        chevronImageView.image = UIImage(systemName: "chevron.down")
        chevronImageView.tintColor = isEnabled ? Colors.tokenDark60 : Colors.tokenDark40
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Create horizontal stack view for content
        let contentStackView = UIStackView(arrangedSubviews: [titleLabel, chevronImageView])
        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.distribution = .fill
        contentStackView.spacing = 8
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(contentStackView)
        
        // Configure button
        button.backgroundColor = .clear
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isEnabled = isEnabled
        
        // Add container view to button
        button.addSubview(containerView)
        
        // Đảm bảo containerView không block touch events của button
        // Button sẽ nhận touch events và trigger action
        containerView.isUserInteractionEnabled = false
        
        // Constraints
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: button.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            contentStackView.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing56),
            
            chevronImageView.widthAnchor.constraint(equalToConstant: 16),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16)
        ])
        
        // Đảm bảo button có thể nhận touch events
        // Thêm tap gesture vào button để đảm bảo nó hoạt động
        if isEnabled {
            // Button đã có target action được add ở nơi khác (districtTapped, wardTapped)
            // Chỉ cần đảm bảo button có thể nhận touch
            button.isUserInteractionEnabled = true
        }
        
        // Store reference to title label in button's associated object or use a custom property
        // For simplicity, we'll update the title by finding the label with tag
        button.setTitle(titleLabel.text ?? "", for: .normal) // Store initial text
        
        // Add overlay view for disabled state
        if !isEnabled {
            let overlayView = UIView()
            overlayView.backgroundColor = UIColor.white.withAlphaComponent(0.6)
            overlayView.layer.cornerRadius = BorderRadius.tokenBorderRadius12
            overlayView.isUserInteractionEnabled = false
            overlayView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(overlayView)
            
            NSLayoutConstraint.activate([
                overlayView.topAnchor.constraint(equalTo: containerView.topAnchor),
                overlayView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                overlayView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                overlayView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
        }
        
        stackView.addArrangedSubview(button)
        
        // Store title label reference for later updates
        objc_setAssociatedObject(button, "titleLabel", titleLabel, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private func getTitleLabel(from button: UIButton) -> UILabel? {
        return objc_getAssociatedObject(button, "titleLabel") as? UILabel
    }
    
    private func updateCountryButton() {
        let country = LocationData.vietnam
        if let titleLabel = getTitleLabel(from: countryPickerButton) {
            titleLabel.text = country.name
        }
        selectedCountryId = country.id
    }
    
    private func updateProvinceButton() {
        let province = LocationData.haNoi
        if let titleLabel = getTitleLabel(from: provincePickerButton) {
            titleLabel.text = province.name
        }
        selectedProvinceId = province.id
        // Reset district and ward when province changes
        selectedDistrictId = 0
        selectedWardId = 0
        updateDistrictButton()
        updateWardButton()
    }
    
    private func updateDistrictButton() {
        let text: String
        if selectedDistrictId > 0, let district = LocationData.getDistrict(by: selectedDistrictId) {
            text = district.name
        } else {
            text = "select_district".localized()
        }
        
        // Update title label - try multiple ways
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Method 1: Get from associated object
            if let titleLabel = self.getTitleLabel(from: self.districtPickerButton) {
                titleLabel.text = text
                return
            }
            
            // Method 2: Find label in button's subviews
            if let containerView = self.districtPickerButton.subviews.first,
               let contentStackView = containerView.subviews.first as? UIStackView,
               let titleLabel = contentStackView.arrangedSubviews.first as? UILabel {
                titleLabel.text = text
                return
            }
            
            // Method 3: Find by tag
            if let titleLabel = self.districtPickerButton.viewWithTag(999) as? UILabel {
                titleLabel.text = text
                return
            }
            
        }
        
        // Reset ward when district changes
        if selectedDistrictId == 0 {
            selectedWardId = 0
            updateWardButton()
        }
    }
    
    private func updateWardButton() {
        let text: String
        if selectedWardId > 0, let ward = LocationData.getWard(by: selectedWardId, in: selectedDistrictId) {
            text = ward.name
        } else {
            text = "select_ward".localized()
        }
        
        // Update title label - try multiple ways
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Method 1: Get from associated object
            if let titleLabel = self.getTitleLabel(from: self.wardPickerButton) {
                titleLabel.text = text
                return
            }
            
            // Method 2: Find label in button's subviews
            if let containerView = self.wardPickerButton.subviews.first,
               let contentStackView = containerView.subviews.first as? UIStackView,
               let titleLabel = contentStackView.arrangedSubviews.first as? UILabel {
                titleLabel.text = text
                return
            }
            
            // Method 3: Find by tag
            if let titleLabel = self.wardPickerButton.viewWithTag(999) as? UILabel {
                titleLabel.text = text
                return
            }
            
        }
    }
    
    @objc private func countryTapped() {
        // Only Vietnam is available, so no action needed
        // But we can show an alert if needed
    }
    
    @objc private func provinceTapped() {
        // Only Hà Nội is available, so no action needed
        // But we can show an alert if needed
    }
    
    @objc private func districtTapped() {
        let districts = LocationData.districts
        showLocationPicker(title: "select_district".localized(), items: districts) { [weak self] selectedItem in
            guard let self = self else { return }
            self.selectedDistrictId = selectedItem.id
            // Update UI on main thread
            DispatchQueue.main.async {
                self.updateDistrictButton()
                self.updateWardButton()
            }
        }
    }
    
    @objc private func wardTapped() {
        guard selectedDistrictId > 0 else {
            showAlert(title: "error".localized(), message: "please_select_district_first".localized())
            return
        }
        
        let wards = LocationData.getWards(for: selectedDistrictId)
        showLocationPicker(title: "select_ward".localized(), items: wards) { [weak self] selectedItem in
            guard let self = self else { return }
            self.selectedWardId = selectedItem.id
            // Update UI on main thread
            DispatchQueue.main.async {
                self.updateWardButton()
            }
        }
    }
    
    private func showLocationPicker(title: String, items: [LocationItem], completion: @escaping (LocationItem) -> Void) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        for item in items {
            let action = UIAlertAction(title: item.name, style: .default) { [weak self] _ in
                // Đảm bảo completion được gọi trên main thread
                DispatchQueue.main.async {
                    completion(item)
                    // Force update UI
                    self?.view.setNeedsLayout()
                    self?.view.layoutIfNeeded()
                }
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "cancel".localized(), style: .cancel)
        alertController.addAction(cancelAction)
        
        // For iPad
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // Present từ view controller hiện tại
        // Nếu đang trong CardViewController, cần present từ parent
        var presentingVC: UIViewController = self
        if let parentVC = parent {
            presentingVC = parentVC
        } else if let presenting = presentingViewController {
            presentingVC = presenting
        }
        
        presentingVC.present(alertController, animated: true)
    }
    
    private func setupDefaultAddressCheckbox(stackView: UIStackView) {
        defaultAddressStack.axis = .horizontal
        defaultAddressStack.spacing = Spacing.tokenSpacing08
        defaultAddressStack.alignment = .center
        defaultAddressStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Square Checkbox using ECoTick style with custom icons
        let bundle = Bundle(for: ECoTick.self)
        defaultAddressCheckbox.image = HelperFunction.getImage(named: "ic_checkbox_uncheck_24", in: bundle)
        defaultAddressCheckbox.contentMode = .scaleAspectFit
        defaultAddressCheckbox.isUserInteractionEnabled = true
        defaultAddressCheckbox.translatesAutoresizingMaskIntoConstraints = false
        
        // Label with italic font
        defaultAddressLabel.text = "set_as_default_shipping".localized()
        defaultAddressLabel.font = UIFont.italicSystemFont(ofSize: 14) // Italic font
        defaultAddressLabel.textColor = Colors.tokenDark100
        defaultAddressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        defaultAddressStack.addArrangedSubview(defaultAddressCheckbox)
        defaultAddressStack.addArrangedSubview(defaultAddressLabel)
        
        // Add tap gesture to stack view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(defaultAddressTapped))
        defaultAddressStack.addGestureRecognizer(tapGesture)
        defaultAddressStack.isUserInteractionEnabled = true
        
        stackView.addArrangedSubview(defaultAddressStack)
        
        // Checkbox size constraint (24x24 for ic_checkbox_uncheck_24)
        NSLayoutConstraint.activate([
            defaultAddressCheckbox.widthAnchor.constraint(equalToConstant: Sizing.tokenSizing24),
            defaultAddressCheckbox.heightAnchor.constraint(equalToConstant: Sizing.tokenSizing24)
        ])
    }
    
    private func updateCheckboxImage() {
        let bundle = Bundle(for: ECoTick.self)
        if isCheckboxSelected {
            // Use ic_right_check_16_green when selected
            defaultAddressCheckbox.image = HelperFunction.getImage(named: "ic_right_check_16_green", in: bundle)
        } else {
            // Use ic_checkbox_uncheck_24 when unselected
            defaultAddressCheckbox.image = HelperFunction.getImage(named: "ic_checkbox_uncheck_24", in: bundle)
        }
    }
    
    // MARK: - Actions
    
    @objc private func defaultAddressTapped() {
        isCheckboxSelected.toggle()
        updateCheckboxImage()
    }
    
    // MARK: - Location List
    
    private func showLocationList() {
        // Prevent opening multiple times - if card already exists and is visible, just show it
        if let existingCard = cardViewController, existingCard.parent != nil {
            existingCard.show()
            return
        }
        
        // If card exists but is not attached (was dismissed), clean it up first
        if cardViewController != nil {
            cardViewController?.detach()
            cardViewController = nil
        }
        
        // Create Card Configuration for deCommand mode (onDemand)
        // Height: reduced by 100pt from full screen
        let screenHeight = view.bounds.height
        let cardHeight = screenHeight - 120
        let cardConfig = CardConfiguration(
            expandedHeight: cardHeight,
            collapsedHeight: cardHeight,
            presentationMode: .onDemand,
            enableGesture: true
        )
        
        // Create Card Controller
        let cardController = DefaultCardController(configuration: cardConfig)
        
        // Create Card View Controller
        let cardVC = CardViewController.create(with: cardController)
        
        // Attach to current view controller
        cardVC.attach(to: self)
        
        // Store reference
        cardViewController = cardVC
        
        // Create LocationListViewController as content
        let appDIContainer = AppDIContainer()
        let locationListDIContainer = appDIContainer.makeLocationListDIContainer()
        let locationListVC = locationListDIContainer.makeLocationListViewController()
        
        // Setup callback when address is selected
        if let locationListController = locationListVC.controller as? DefaultLocationListController {
            locationListController.onAddressSelected = { [weak self, weak cardVC] address in
                // Fill form with selected address
                self?.contactPersonNameTextField.text = address.contactPersonName
                self?.contactPersonNumberTextField.text = address.contactPersonNumber
                self?.addressDetailTextField.text = address.addressDetail
                self?.selectedCountryId = address.countryId
                self?.selectedProvinceId = address.provinceId
                self?.selectedDistrictId = address.districtId
                self?.selectedWardId = address.wardId
                self?.selectedAddressType = address.addressType
                
                // Update location pickers
                self?.updateCountryButton()
                self?.updateProvinceButton()
                self?.updateDistrictButton()
                self?.updateWardButton()
                
                // Update address type segmented control
                switch address.addressType {
                case "shipping":
                    self?.addressTypeSegmentedControl.selectedSegmentIndex = 0
                case "shop":
                    self?.addressTypeSegmentedControl.selectedSegmentIndex = 1
                case "other":
                    self?.addressTypeSegmentedControl.selectedSegmentIndex = 2
                default:
                    self?.addressTypeSegmentedControl.selectedSegmentIndex = 0
                }
                
                // Dismiss card
                cardVC?.dismiss()
                // Clear reference when dismissed
                if cardVC === self?.cardViewController {
                    self?.cardViewController = nil
                }
            }
        }
        
        // Set LocationListViewController as content of CardViewController
        cardVC.setContent(locationListVC)
        
        // Show card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cardVC.show()
        }
    }
    
    // MARK: - Error Handler Override
    
    override func handleError(_ error: Error?) {
        guard let error = error else { return }
        showAlert(title: "Error", message: error.localizedDescription)
    }
    
    private func showSuccessAlert(message: String) {
        addressController.successMessage.value = nil
        showAlert(
            title: "Success",
            message: message,
            completion: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        )
    }
}

// MARK: - EcoButtonDelegate

extension AddressViewController: EcoButtonDelegate {
    
    func buttonDidTap(_ button: EcoButton) {
        guard button == saveButton else { return }
        
        addressController.didTapSave(
            contactPersonName: contactPersonNameTextField.text ?? "",
            contactPersonNumber: contactPersonNumberTextField.text ?? "",
            addressDetail: addressDetailTextField.text ?? "",
            countryId: selectedCountryId,
            provinceId: selectedProvinceId,
            districtId: selectedDistrictId,
            wardId: selectedWardId,
            addressType: selectedAddressType,
            isDefault: isCheckboxSelected
        )
    }
}
