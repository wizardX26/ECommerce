//
//  ProfileViewController.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import UIKit
import PhotosUI

final class ProfileViewController: EcoViewController {
    
    // MARK: - UI Components
    
    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    private var profileController: ProfileController! {
        get { controller as? ProfileController }
    }
    
    // Store reference to CardViewController to prevent opening multiple times
    private var cardViewController: CardViewController?
    
    // Store reference to popup
    private var imagePickerPopup: ProfileImagePickerPopup?
    
    // MARK: - Lifecycle
    
    static func create(
        with profileController: ProfileController
    ) -> ProfileViewController {
        let view = ProfileViewController.instantiateViewController()
        view.controller = profileController
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isSwipeBackEnabled = true
        setupViews()
        bindProfileSpecific()
        profileController.viewDidLoad()
    }
    
    // MARK: - Common Binding Override
    
    override func bindCommon() {
        super.bindCommon()
        bindProfileSpecific()
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
    
    // MARK: - Profile-Specific Binding
    
    private func bindProfileSpecific() {
        profileController.user.observe(on: self) { [weak self] _ in
            self?.tableView.reloadData()
        }
        
        profileController.error.observe(on: self) { [weak self] error in
            guard let self = self, let error = error else { return }
            self.showAlert(title: "Error", message: error.localizedDescription)
        }
        
        profileController.loading.observe(on: self) { [weak self] isLoading in
            // Show/hide loading indicator if needed
        }
        
        // Setup callback for editing fields
        if let defaultController = profileController as? DefaultProfileController {
            defaultController.onEditField = { [weak self] fieldType in
                self?.showEditProfile(for: fieldType)
            }
            
            // Setup callback for account icon tap
            defaultController.onAccountIconTap = { [weak self] in
                self?.showImagePickerPopup()
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        view.backgroundColor = .systemBackground
        
        // TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .systemGroupedBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Register cell
        tableView.register(cell: ProfileTableViewCell.self)
        
        // Constraints
        let navBarHeight = profileController.navigationBarInitialHeight
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: navBarHeight),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Edit Profile
    
    private func showEditProfile(for fieldType: ProfileFieldType) {
        // Get field title and subtitle from cell (always get fresh data)
        let cellTitle: String
        let cellSubtitle: String
        
        switch fieldType {
        case .fullName:
            cellTitle = getAccountInfoCellTitle(for: 0)
            cellSubtitle = getAccountInfoCellSubtitle(for: 0)
        case .email:
            cellTitle = getAccountInfoCellTitle(for: 1)
            cellSubtitle = getAccountInfoCellSubtitle(for: 1)
        case .phone:
            cellTitle = getAccountInfoCellTitle(for: 2)
            cellSubtitle = getAccountInfoCellSubtitle(for: 2)
        case .changePassword:
            cellTitle = getAccountInfoCellTitle(for: 3)
            cellSubtitle = "" // Change password has no subtitle
        }
        
        // Check if card already exists and is attached
        if let existingCard = cardViewController, existingCard.parent != nil {
            // Card exists, just update content with new data and show
            let appDIContainer = AppDIContainer()
            let profileDIContainer = appDIContainer.makeProfileDIContainer()
            let editProfileVC = profileDIContainer.makeEditProfileViewController(
                for: fieldType,
                screenTitle: cellTitle,
                currentValue: cellSubtitle
            )
            
            // Setup callback to refresh user info when save is successful
            setupEditProfileSuccessCallback(for: editProfileVC, cardVC: existingCard)
            
            // Update content with new EditProfileViewController
            existingCard.setContent(editProfileVC)
            existingCard.show()
            return
        }
        
        // If card exists but is not attached, clean it up first
        if cardViewController != nil {
            cardViewController?.detach()
            cardViewController = nil
        }
        
        // Create Card Configuration for onDemand mode
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
        
        // Create EditProfileViewController as content with title and subtitle from cell
        let appDIContainer = AppDIContainer()
        let profileDIContainer = appDIContainer.makeProfileDIContainer()
        let editProfileVC = profileDIContainer.makeEditProfileViewController(
            for: fieldType,
            screenTitle: cellTitle,
            currentValue: cellSubtitle
        )
        
        // Set EditProfileViewController as content of CardViewController
        cardVC.setContent(editProfileVC)
        
        // Setup callback to refresh user info when save is successful
        setupEditProfileSuccessCallback(for: editProfileVC, cardVC: cardVC)
        
        // Show card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            cardVC.show()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh user info when view appears (in case user updated profile)
        if let defaultController = profileController as? DefaultProfileController {
            defaultController.onViewWillAppear()
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupEditProfileSuccessCallback(for editProfileVC: EditProfileViewController, cardVC: CardViewController) {
        if let editProfileController = editProfileVC.controller as? DefaultEditProfileController {
            editProfileController.successMessage.observe(on: self) { [weak self, weak cardVC] message in
                guard let self = self, let message = message, !message.isEmpty else { return }
                
                // Refresh user info after successful save
                if let defaultProfileController = self.profileController as? DefaultProfileController {
                    defaultProfileController.viewDidLoad() // Refresh user data
                }
                
                // Dismiss card after a short delay to allow success message to be shown
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    cardVC?.dismiss()
                    // Clear reference after dismiss
                    if cardVC === self.cardViewController {
                        self.cardViewController = nil
                    }
                }
            }
        }
    }
    
    // MARK: - Image Picker Popup
    
    private func showImagePickerPopup() {
        // Dismiss existing popup if any
        imagePickerPopup?.dismiss()
        imagePickerPopup = nil
        
        // Create new popup
        let popup = ProfileImagePickerPopup()
        
        // Setup callbacks
        popup.onChooseFromPhotos = { [weak self] in
            self?.presentPhotoLibrary()
        }
        
        popup.onOpenCamera = { [weak self] in
            self?.presentCameraViewController()
        }
        
        popup.onCancel = { [weak self] in
            // Just dismiss
        }
        
        // Show popup
        popup.show(in: view)
        imagePickerPopup = popup
    }
    
    // MARK: - Camera & Photo Library
    
    private func presentCameraViewController() {
        // Present camera in normal mode using CameraHelper
        CameraHelper.presentCamera(
            mode: .aiSearch,
            from: self,
            onImageCaptured: { [weak self] image in
                self?.handleCapturedImage(image)
            },
            onDismiss: nil
        )
    }
    
    private func presentPhotoLibrary() {
        if #available(iOS 14, *) {
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = 1
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            present(picker, animated: true)
        } else {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            present(picker, animated: true)
        }
    }
    
    private func handleCapturedImage(_ image: UIImage) {
        // TODO: Upload image to server
        // Here you can add logic to upload the image
        // For now, just show success message
        showAlert(title: "success".localized(), message: "image_captured_success".localized())
    }
    
    // MARK: - Helper Methods
    
    private func getAccountInfoCellTitle(for row: Int) -> String {
        switch row {
        case 0: return "full_name".localized()
        case 1: return "email".localized()
        case 2: return "phone_number".localized()
        case 3: return "change_password".localized()
        default: return ""
        }
    }
    
    private func getAccountInfoCellSubtitle(for row: Int) -> String {
        guard let user = profileController.user.value else {
            return ""
        }
        
        switch row {
        case 0:
            return user.fullName
        case 1:
            return user.email
        case 2:
            return user.phone.isEmpty ? "incomplete".localized() : user.phone
        case 3:
            return "" // Change password has no subtitle
        default:
            return ""
        }
    }
}

// MARK: - UITableViewDataSource

extension ProfileViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // Only Account Info, removed Shop Info section
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4 // Full name, Email, Phone number, Change password
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: ProfileTableViewCell = tableView.dequeueReusableCell(at: indexPath)
        
        let title = getAccountInfoCellTitle(for: indexPath.row)
        let subtitle = getAccountInfoCellSubtitle(for: indexPath.row)
        
        // Special handling for email row (index 1) - show "notVerify" label if email not verified
        if indexPath.row == 1, let user = profileController.user.value, !user.isEmailVerified {
            cell.fill(
                with: title,
                subtitle: subtitle.isEmpty ? nil : subtitle,
                showNotVerify: true,
                onNotVerifyTap: { [weak self] in
                    self?.handleNotVerifyEmailTap()
                }
            )
        } else {
            cell.fill(with: title, subtitle: subtitle.isEmpty ? nil : subtitle)
        }
        
        return cell
    }
    
    private func handleNotVerifyEmailTap() {
        guard let user = profileController.user.value else { return }
        
        let alert = UIAlertController(
            title: nil,
            message: "Send verify link to this email address?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            self?.resendEmailVerification()
        })
        
        present(alert, animated: true)
    }
    
    private func resendEmailVerification() {
        // Show loading
        profileController.loading.value = true
        
        let appDIContainer = AppDIContainer.shared
        let authSceneDIContainer = appDIContainer.makeAuthSceneDIContainer()
        let authRepository = authSceneDIContainer.makeAuthRepository()
        
        authRepository.resendEmailVerification { [weak self] result in
            DispatchQueue.main.async {
                self?.profileController.loading.value = false
                
                switch result {
                case .success:
                    let alert = UIAlertController(
                        title: "Success",
                        message: "Verification email has been sent to your email address.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true)
                    
                case .failure(let error):
                    let alert = UIAlertController(
                        title: "Error",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "account_information".localized()
    }
}

// MARK: - UITableViewDelegate

extension ProfileViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        profileController.didSelectCell(at: 0, row: indexPath.row) // Always use section 0 now
    }
}

// MARK: - PHPickerViewControllerDelegate

@available(iOS 14, *)
extension ProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let itemProvider = results.first?.itemProvider,
              itemProvider.canLoadObject(ofClass: UIImage.self) else {
            return
        }
        
        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.handleCapturedImage(image)
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let editedImage = info[.editedImage] as? UIImage {
            handleCapturedImage(editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            handleCapturedImage(originalImage)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
