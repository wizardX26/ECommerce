import Foundation

public enum CoreUIKitLocalization: String {
    case list_receivers
    case scan_qr_code
    case qr_code_info
    case payment_code
    case enter_store_code
    case use_image
    case set_auto_payment
    case reuse_transaction
    case linked_account
    case number_of_linked_accounts
    case viettelpay_account
    case show_balance
    case hide_balance
    case show_detail
    case hide_detail
    case recharge
    case hunt_point
    case more_info
    case active_now
    case use
    case use_now
    case all
    case free
    case share
    case close
    case done
    case save
    case delete
    case change
    case contacts
    case notice
    case enter_pin_notice
    case enter_otp_notice
    case processing_notice
    case transaction_failed
    case success
    case fail
    case processing
    case cancel
    case cancellation
    case canceled
    case percent
    case agree
    case unCheck
    
    case balance
    case balance_not_enough
    case balance_not_enough_content
    
    case card_number_not_supported
    case card_number_not_exist
    case card_number_not_supportedMoney
    case budget_over_limit
    case budget_over_limit_recharge
    case budget_over_limit_content
    case budget_daily
    case budget_enough
    case budget_enough_mm1
    case budget_update
    case budget_view
    case budget_view_MM1
    case budget_over_limit_recharge_content
    case budget_over_limit_recharge_content_MM1
	case budget_over_limit_buy_voucher
	case budget_over_limit_buy_voucher_content
	case budget_enough_voucher
	case charge_voucher_point
    
    case change_source
    
    case otp_verify
    case otp_place_holder
    case otp_out_of_time
    case ignore
    case confirm
    case resend
    case resendOTP

    case transaction_money

    case accept_permission
    case permission_contact_title
    case permission_camera_title
    case permission_gallery_title
    case permission_location_title
    
    case permission_contact_des
    case permission_camera_des
    case permission_gallery_des
    case permission_location_des
    
    case label_telco_account
    case continues
    case charge_amount
    case month
    case remaining_budget
    
    case button_fixed_label_default
    case button_fixed_info_cell_title
    case button_fixed_info_cell_value
    
    case swipe_pin_title
    case swipe_unpin_title
    case swipe_edit_title
    case swipe_delete_title
    case swipe_agree_title
    case swipe_reuse_title
    case swipe_detail_title
    case swipe_seen_title
    case swipe_auto_payment_title
    
    public var localized: String {
        return rawValue.localized(using: "")
    }
    
//    public var localized: String {
//        if ECoConfigure.shared.isCocoaPodsState() {
//            let bundle = Bundle(for: ECoButton.self)
//            if let bundleUrl = bundle.url(forResource: "CoreUIKitBundle", withExtension: "bundle") {
//                let podBundle = Bundle(url: bundleUrl)
//                return rawValue.localized(using: "CoreUIKit", in: podBundle)
//            }
//            return ""
//        } else {
//            return rawValue.localized(using: "CoreUIKit", in: Bundle(for: ECoButton.self))
//        }
//    }
}
