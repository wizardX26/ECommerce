//
//  CommonViewsLocalization.swift
//  CommonViews
//
//  Created by Natariannn on 11/12/20.
//  Copyright © 2020 ViettelPay App Team. All rights reserved.
//

import Foundation

public enum CommonViewsLocalization: String {
    case balance_not_enough
    case bank_with_name
    case bankplus
    case bs_title_voucher
    case bs_title_sources
    case bs_title_telco_account
    
    case card_and_name
    case mb_bank_with_number
    
    case discount
    case cashBack
    case discount_campaign
    case discount_amount
    case description_voucher
    case discount_cdt
    case viettel_loyalty
    
    case free
    case go_home
    
    case money_title
    case payment_money_title
    case total_money_title
    case debit_telco

    case confirm_button_payment
    case confirm
    case share
    
    case confirm_header_account
	case confirm_header_account_list
    case confirm_header_bill
    case confirm_header_voucher
    case confirm_header_voucher_loan
    case confirm_header_pay
    case confirm_header_pay2
    
    case confirm_title_payment
    case confirm_title_recharge
    case confirm_title_transfer
    case confirm_title_withdrawal
    case confirm_title_fee_payment
    
    case password_bankplus
    
    case payment_continue
    case payment_header
    case payment_success
    case processing_notice
    
    case recharge_continue
    case recharge_header
    case recharge_success
    case recharge_other_over_budget
    
    case select_voucher
    
    case topup_continue
    case topup_header
    case topup_success
    
    case transfer_continue
    case transfer_header
    case transfer_success
    
    case transaction_fee
	case transaction_fee_not_count
    
    case bundle_fee
    
    case unselect_voucher
    
    case share_content
    
    case result_share_coachmark_content
    
    case recomend
    
    case voucher_used
    
    case content_default
    
    case content_default_mm
    
    case title_moment_covid_vacxin
    
    case thank_you_very_much
    
    case label_donate_covid_vacxin
    
    case donate_continue
    
    case share_here
    
    case timeout
    
    case failed
    
    case fe_step_one
    
    case fe_step_two
    
    case prepaid_amount
    
    case debit_amount
    
    case prepaid_month
    case you_have_not_enough_balance_to_process_transaction
    
    case tb05
    case tb06
    case tb07
    
    case voucher_unavailable_title
    case voucher_unavailable_message
    
    case insurance_fee
    case campaign
    
    case cannot_charge_money
    case over_limit_charge_money
    case warning_only_mm_less_than_consumption
    case warning_only_mm_more_than_consumption
    case change_money_recharge
    case active_viettelpay
    case change_account
    case warning_both_MM_VTP_more_than_consumption
    case warning_both_MM_VTP_less_than_consumption
   
    public var localized: String {
        return rawValue.localized(using: "")
    }
}
