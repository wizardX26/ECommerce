//
//  DoubleExtensions.swift
//  CoreUtilsKit
//
//  Created by NhoNH on 14/01/2024.
//  Copyright © 2024 ViettelPay App Team. All rights reserved.
//

import Foundation

public extension Double {
    func convertToString() -> String {
        let rounded = self.rounded()
        return String(format: "%.0lf", rounded)
    }
    
    /// Format số bỏ .00 khi không cần thiết
    /// 100.00 → "100"
    /// 100.50 → "100.5"
    /// 27000000.00 → "27000000"
    var formattedWithoutTrailingZeros: String {
        // Nếu là số nguyên (không có phần thập phân)
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        }
        
        // Nếu có phần thập phân, format và bỏ .00 thừa
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 10 // Cho phép nhiều chữ số thập phân
        formatter.minimumFractionDigits = 0 // Không bắt buộc có chữ số thập phân
        formatter.decimalSeparator = "."
        
        guard let formatted = formatter.string(from: NSNumber(value: self)) else {
            return String(self)
        }
        
        // Bỏ .00 thừa ở cuối
        var result = formatted
        if result.contains(".") {
            // Loại bỏ các số 0 thừa ở cuối
            while result.hasSuffix("0") && result.contains(".") {
                result = String(result.dropLast())
            }
            // Loại bỏ dấu chấm nếu không còn phần thập phân
            if result.hasSuffix(".") {
                result = String(result.dropLast())
            }
        }
        
        return result
    }
    
    /// Format số với separator (dấu phẩy) và bỏ .00 khi không cần
    /// 100000.00 → "100,000"
    /// 100000.50 → "100,000.5"
    var formattedWithSeparatorWithoutTrailingZeros: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 10
        formatter.minimumFractionDigits = 0
        formatter.decimalSeparator = "."
        
        guard let formatted = formatter.string(from: NSNumber(value: self)) else {
            return formattedWithoutTrailingZeros
        }
        
        // Bỏ .00 thừa ở cuối
        var result = formatted
        if result.contains(".") {
            while result.hasSuffix("0") && result.contains(".") {
                result = String(result.dropLast())
            }
            if result.hasSuffix(".") {
                result = String(result.dropLast())
            }
        }
        
        return result
    }
}
