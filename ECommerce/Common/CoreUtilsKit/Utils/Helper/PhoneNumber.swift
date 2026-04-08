//
//  PhoneNumber.swift
//  CoreUtilsKit
//
//  Created by Bui Thien Thien on 8/7/20.
//  Copyright © 2020 ViettelPay App Team. All rights reserved.
//

import Foundation

public class PhoneNumber {
    public static var shared: PhoneNumber = PhoneNumber()
    
    public func isVinaphone(_ phoneNumber: String) -> Bool {
        let trimPhoneNumber: String = phoneNumber.trimmingCharacters(in: .whitespaces)
        let regex: String = "^(8432|8433|8434|8435|8436|8437|8438|8439|8486|8487|8496|8497|8498|032|033|034|035|036|037|038|039|086|087|096|097|098)[0-9]+$"
        guard let _: Range = trimPhoneNumber.range(of: regex, options: .regularExpression) else {
            return false
        }
        return true
    }

    public func isMobiFone(_ phoneNumber: String) -> Bool {
        let trimPhoneNumber: String = phoneNumber.trimmingCharacters(in: .whitespaces)
        let regex: String = "^(8470|8476|8477|8478|8479|8489|8490|8493|070|076|077|078|079|089|090|093)[0-9]+$"
        guard let _: Range = trimPhoneNumber.range(of: regex, options: .regularExpression) else {
            return false
        }
        return true
    }

    public func isViettel(_ phoneNumber: String) -> Bool {
        let trimPhoneNumber: String = phoneNumber.trimmingCharacters(in: .whitespaces)
        let regex: String = "^(8481|8482|8483|8484|8485|8488|8491|8494|081|082|083|084|085|088|091|094)[0-9]+$"
        guard let _: Range = trimPhoneNumber.range(of: regex, options: .regularExpression) else {
            return false
        }
        return true
    }

    public func isVietnamobile(_ phoneNumber: String) -> Bool {
        let trimPhoneNumber: String = phoneNumber.trimmingCharacters(in: .whitespaces)
        let regex: String = "^(8492|8456|8458|8452|092|056|058|052)[0-9]+$"
        guard let _: Range = trimPhoneNumber.range(of: regex, options: .regularExpression) else {
            return false
        }
        return true
    }

    public func isGmobile(_ phoneNumber: String) -> Bool {
        let trimPhoneNumber: String = phoneNumber.trimmingCharacters(in: .whitespaces)
        let regex: String = "^(8499|8459|099|059)[0-9]+$"
        guard let _: Range = trimPhoneNumber.range(of: regex, options: .regularExpression) else {
            return false
        }
        return true
    }
    
    public func isVietnamPhoneNumber(_ phoneNumber: String) -> Bool {
        if isViettel(phoneNumber) || isVinaphone(phoneNumber) || isMobiFone(phoneNumber) || isVietnamobile(phoneNumber) || isGmobile(phoneNumber) || phoneNumber == Constant.applePhoneNumber {
            return true
        }
        return false
    }
}
