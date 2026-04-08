import UIKit
import CommonCrypto

public extension String {
    var toDouble: Double {
      return Double(self) ?? 0
    }
    
    var toInt: Int {
      return Int(self) ?? 0
    }
}

// MARK: - String func
public extension String {

	func trimWhitespaceInMiddle() -> String {
		// Tạo một bản sao của chuỗi đầu vào
		var result = self

		// Sử dụng NSCharacterSet để xác định các khoảng trắng
		let whitespaceSet = CharacterSet.whitespaces

		// Tìm kiếm và thay thế các khoảng trắng thừa ở giữa
		while let range = result.range(of: "\\s{2,}", options: .regularExpression) {
			result.replaceSubrange(range, with: " ")
		}

		// Loại bỏ khoảng trắng ở đầu và cuối
		result = result.trimmingCharacters(in: whitespaceSet)

		return result
	}

    func trim() -> String {
        let result = trimmingCharacters(in: .whitespaces)
        return result
    }
    
    func removeSpacing() -> String {
        let result = trim().replacingOccurrences(of: " ", with: "")
        return result
    }
    
    var toAlphabeString: String {
        let simple = folding(options: [.diacriticInsensitive, .widthInsensitive, .caseInsensitive], locale: nil)
        let nonAlphaNumeric = CharacterSet.alphanumerics.inverted
        let text = simple.components(separatedBy: nonAlphaNumeric).joined(separator: "").uppercased()
        return text.replacingOccurrences(of: "Đ", with: "D")
    }

    var isImageURL: Bool {
        guard let url = URL(string: self) else {
            return false
        }
        let validImageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp"]
        return validImageExtensions.contains(url.pathExtension.lowercased())
    }
    
    /// Ghép URL image với baseURL từ AppConfiguration
    /// Nếu urlString đã là full URL (bắt đầu bằng http/https) thì trả về nguyên bản
    /// Nếu không, ghép với apiBaseURL từ AppConfiguration
    /// - Returns: Full URL string hoặc nil nếu không thể tạo URL hợp lệ
    func fullImageURL() -> String? {
        // Nếu rỗng, trả về nil
        guard !self.isEmpty else {
            return nil
        }
        
        // Nếu đã là full URL, trả về nguyên bản
        if self.hasPrefix("http://") || self.hasPrefix("https://") {
            return self
        }
        
        // Lấy baseURL từ AppConfiguration
        let appConfig = AppConfiguration()
        var baseURL = appConfig.apiBaseURL
        
        // Loại bỏ trailing slash từ baseURL nếu có
        baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        // Đảm bảo imagePath có leading slash
        let imagePath = self.hasPrefix("/") ? self : "/\(self)"
        
        // Ghép lại
        let fullURL = "\(baseURL)\(imagePath)"
        
        // Validate URL
        guard URL(string: fullURL) != nil else {
            return nil
        }
        
        return fullURL
    }
}

// MARK: - String money
// swiftlint:disable cyclomatic_complexity
public extension String {
    private func numberToText(_ number: String) -> String {
        var result = ""
        let number = Int(number) ?? 0
        switch number {
        case 0:
            result = "không"
        case 1:
            result = "một"
        case 2:
            result = "hai"
        case 3:
            result = "ba"
        case 4:
            result = "bốn"
        case 5:
            result = "năm"
        case 6:
            result = "sáu"
        case 7:
            result = "bẩy"
        case 8:
            result = "tám"
        case 9:
            result = "chín"
        default:
            result = ""
        }
        return result
    }
    
    private func unit(_ number: String) -> String {
        var unit = ""
        if number == "1" {
            unit = ""
        }
        if number == "2" {
            unit = "nghìn"
        }
        if number == "3" {
            unit = "triệu"
        }
        if number == "4" {
            unit = "tỷ"
        }
        if number == "5" {
            unit = "nghìn tỷ"
        }
        if number == "6" {
            unit = "triệu tỷ"
        }
        if number == "7" {
            unit = "tỷ tỷ"
        }
        return unit
    }
    
    private func tach(_ input: String) -> String { //swiftlint:disable cyclomatic_complexity
        var result = ""
        if (input == "000") {
            return ""
        }
        if input.count == 3 {
            let text = input.trim() as NSString
            let hundreds = text.substring(with: NSRange(location: 0, length: 1)).trim() as String
            let dozens = text.substring(with: NSRange(location: 1, length: 1)).trim() as String
            let units = text.substring(with: NSRange(location: 2, length: 1)).trim() as String
            
            if (hundreds == "0") && (dozens == "0") {
                result = " không trăm lẻ \(numberToText(units)) "
            }
            if !(hundreds == "0") && (dozens == "0") && (units == "0") {
                result = " \(numberToText(hundreds)) trăm "
            }
            if !(hundreds == "0") && (dozens == "0") && !(units == "0") {
                result = " \(numberToText(hundreds)) trăm lẻ \(numberToText(units)) "
            }
            if (hundreds == "0") && Int(dozens) ?? 0 > 1 && Int(units) ?? 0 > 0 && !(units == "5") {
                result = " không trăm \(numberToText(dozens)) mươi \(numberToText(units)) "
            }
            if (hundreds == "0") && Int(dozens) ?? 0 > 1 && (units == "0") {
                result = " không trăm \(numberToText(dozens)) mươi "
            }
            if (hundreds == "0") && Int(dozens) ?? 0 > 1 && (units == "5") {
                result = " không trăm \(numberToText(dozens)) mươi lăm "
            }
            if (hundreds == "0") && (dozens == "1") && Int(units) ?? 0 > 0 && !(units == "5") {
                result = " không trăm mười \(numberToText(units)) "
            }
            if (hundreds == "0") && (dozens == "1") && (units == "0") {
                result = " không trăm mười "
            }
            if (hundreds == "0") && (dozens == "1") && (units == "5") {
                result = " không trăm mười lăm "
            }
            if Int(hundreds) ?? 0 > 0 && Int(dozens) ?? 0 > 1 && Int(units) ?? 0 > 0 && !(units == "5") {
                if Int(units) == 1 && Int(dozens)! > 1 {
                    result = "\(numberToText(hundreds)) trăm \(numberToText(dozens)) mươi mốt "
                } else if Int(units) == 4 && Int(dozens)! > 1 {
                    result = "\(numberToText(hundreds)) trăm \(numberToText(dozens)) mươi tư "
                } else {
                    result = "\(numberToText(hundreds)) trăm \(numberToText(dozens)) mươi \(numberToText(units)) "
                }
            }
            if Int(hundreds) ?? 0 > 0 && Int(dozens) ?? 0 > 1 && (units == "0") {
                result = "\(numberToText(hundreds)) trăm \(numberToText(dozens)) mươi "
            }
            if Int(hundreds) ?? 0 > 0 && Int(dozens) ?? 0 > 1 && (units == "5") {
                result = "\(numberToText(hundreds)) trăm \(numberToText(dozens)) mươi lăm"
            }
            if Int(hundreds) ?? 0 > 0 && (dozens == "1") && Int(units) ?? 0 > 0 && !(units == "5") {
                result = "\(numberToText(hundreds)) trăm mười \(numberToText(units)) "
            }
            if Int(hundreds) ?? 0 > 0 && (dozens == "1") && (units == "0") {
                result = "\(numberToText(hundreds)) trăm mười "
            }
            if Int(hundreds) ?? 0 > 0 && (dozens == "1") && (units == "5") {
                result = "\(numberToText(hundreds)) trăm mười lăm "
            }
        }
        
        return result
    }
    
    private func tach2(_ input: String) -> String {
        var result = ""
        if (input == "000") {
            return ""
        }
        if input.count == 3 {
            let text = input.trim() as NSString
            let hundreds = text.substring(with: NSRange(location: 0, length: 1)).trim() as String
            let dozens = text.substring(with: NSRange(location: 1, length: 1)).trim() as String
            let units = text.substring(with: NSRange(location: 2, length: 1)).trim() as String
            
            if (hundreds == "0") && (dozens == "0") {
                result = "\(numberToText(units)) "
            }
            if !(hundreds == "0") && (dozens == "0") && (units == "0") {
                result = "\(numberToText(hundreds)) trăm "
            }
            if !(hundreds == "0") && (dozens == "0") && !(units == "0") {
                result = "\(numberToText(hundreds)) trăm lẻ \(numberToText(units)) "
            }
            if (hundreds == "0") && Int(dozens) ?? 0 > 1 && Int(units) ?? 0 > 0 && !(units == "5") {
                if Int(units) == 1 && Int(dozens)! > 1 {
                    result = "\(numberToText(dozens)) mươi mốt "
                } else if Int(units) == 4 && Int(dozens)! > 1 {
                    result = "\(numberToText(dozens)) mươi tư "
                } else {
                    result = "\(numberToText(dozens)) mươi \(numberToText(units)) "
                }
            }
            if (hundreds == "0") && Int(dozens) ?? 0 > 1 && (units == "0") {
                result = "\(numberToText(dozens)) mươi "
            }
            if (hundreds == "0") && Int(dozens) ?? 0 > 1 && (units == "5") {
                result = "\(numberToText(dozens)) mươi lăm "
            }
            if (hundreds == "0") && (dozens == "1") && Int(units) ?? 0 > 0 && !(units == "5") {
                result = "mười \(numberToText(units)) "
            }
            if (hundreds == "0") && (dozens == "1") && (units == "0") {
                result = "mười "
            }
            if (hundreds == "0") && (dozens == "1") && (units == "5") {
                result = "mười lăm "
            }
            if Int(hundreds) ?? 0 > 0 && Int(dozens) ?? 0 > 1 && Int(units) ?? 0 > 0 && !(units == "5") {
                result = "\(numberToText(hundreds)) trăm \(numberToText(dozens)) mươi \(numberToText(units)) "
            }
            if Int(hundreds) ?? 0 > 0 && Int(dozens) ?? 0 > 1 && (units == "0") {
                result = "\(numberToText(hundreds)) trăm \(numberToText(dozens)) mươi "
            }
            if Int(hundreds) ?? 0 > 0 && Int(dozens) ?? 0 > 1 && (units == "5") {
                result = "\(numberToText(hundreds)) trăm \(numberToText(dozens)) mươi lăm "
            }
            if Int(hundreds) ?? 0 > 0 && (dozens == "1") && Int(units) ?? 0 > 0 && !(units == "5") {
                result = "\(numberToText(hundreds)) trăm mười \(numberToText(units)) "
            }
            if Int(hundreds) ?? 0 > 0 && (dozens == "1") && (units == "0") {
                result = "\(numberToText(hundreds)) trăm mười "
            }
            if Int(hundreds) ?? 0 > 0 && (dozens == "1") && (units == "5") {
                result = "\(numberToText(hundreds)) trăm mười lăm "
            }
        }
        return result
    }
    
    func convertToWord() -> String {
        do {
            var money = replacingOccurrences(of: ".", with: "").trim()
            money = components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
            
            let scanner = Scanner(string: money)
            let isNumeric = scanner.scanFloat(nil) && scanner.isAtEnd
            if !isNumeric {
                return ""
            }
            
            if Double(money) ?? 0.0 == 0 {
                return ""
            }
            var textNumber = ""
            var modSection = ""
            var surplusSection = ""
            
            var segments = money.count / 3
            let mod = money.count - segments * 3
            var dau = "[+]"
            // Dau [+,-]
            if Double(money) ?? 0.0 < 0 {
                dau = "[-]"
            } else {
                dau = ""
            }
            // Tách hàng lớn nhất
            if mod == 1 {
                modSection = "00\((money as NSString).substring(with: NSRange(location: 0, length: 1)))"
            }
            if mod == 2 {
                modSection = "0\((money as NSString).substring(with: NSRange(location: 0, length: 2)))"
            }
            if mod == 0 {
                modSection = "000"
            }
            // Tách hàng còn lại sau mod :
            surplusSection = (money as NSString).substring(with: NSRange(location: mod, length: money.count - mod))
            //  Đơn vị hàng mod
            let unitMod = segments + 1
            if mod > 0 {
                textNumber = "\(tach2(modSection).trim()) \(unit(String(format: "%li", unitMod)))"
            }
            // Tách 3 trong tach_conlai
            var segmentsCount = segments
            let originSegments = segments
            var index = 1
            var divide = ""
            var divideTemp = ""
            while segmentsCount > 0 {
                var text = surplusSection as NSString
                divide = text.substring(with: NSRange(location: 0, length: 3))
                divideTemp = divide
                textNumber = "\(textNumber.trim()) \(tach(divide).trim())"
                segments = originSegments + 1 - index
                if !(divideTemp == "000") {
                    textNumber = "\(textNumber.trim()) \(unit(String(format: "%li", Int(segments))))"
                }
                text = text.substring(with: NSRange(location: 3, length: text.length - 3)) as NSString
                surplusSection = text as String
                segmentsCount -= 1
                index += 1
            }
            if !textNumber.isEmpty {
                textNumber = textNumber.trim()
                var textTemp = textNumber as NSString
                let first = textTemp.substring(with: NSRange(location: 0, length: 1)).uppercased()
                textTemp = "\(first)\(textTemp.substring(with: NSRange(location: 1, length: textTemp.length - 1)))" as NSString
                textTemp = "\(dau) \(textTemp.substring(with: NSRange(location: 0, length: 1)))\((textTemp.substring(with: NSRange(location: 1, length: textTemp.length - 1))).trim()) đồng" as NSString
                textNumber = textTemp as String
            }
            
            return textNumber.trim()
        }
    }
    
    func removeDigit() -> String {
        let stringMoney = trimmingCharacters(in: CharacterSet(charactersIn: "0123456789.,").inverted)
        let last2Chars = stringMoney.suffix(2)
        let last3Chars = stringMoney.suffix(3)
        var final = stringMoney
        if last2Chars.prefix(1) == "." || last2Chars.prefix(1) == "," {
            final = String(stringMoney.dropLast(2))
        }
        if last3Chars.prefix(1) == "." || last3Chars.prefix(1) == "," {
            final = String(stringMoney.dropLast(3))
        }
        return final
    }
    
    func removeDot() -> String {
        let final = replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "?", with: "")
        return final
    }
    
    func convertToMoneyFormat() -> String {
        if isEmpty {
            return ""
        }
        let number = removeDigit().components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
        let numberFormat = NumberFormatter()
        numberFormat.numberStyle = .decimal
        numberFormat.decimalSeparator = ","
        numberFormat.groupingSeparator = "."
        numberFormat.locale = Locale(identifier: "en_US")
        let output = "\(numberFormat.string(from: NSNumber(value: Double(number) ?? 0.0)) ?? "")".replacingOccurrences(of: ",", with: ".")
        return output
    }

    func convertToMoneyText() -> String {
        if isEmpty {
            return ""
        }
        let number = self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
        let numberFormat = NumberFormatter()
        numberFormat.numberStyle = .decimal
        numberFormat.decimalSeparator = ","
        numberFormat.groupingSeparator = "."
        numberFormat.groupingSize = 3
        numberFormat.locale = Locale(identifier: "en_US")
        numberFormat.usesGroupingSeparator = true
        numberFormat.maximumFractionDigits = 0
        let output = "\(numberFormat.string(from: NSNumber(value: Double(number) ?? 0.0)) ?? "")".replacingOccurrences(of: ",", with: ".")
        return output
    }

    func convertToMoneyVN() -> String {
        if convertToMoneyFormat() == "" {
            return ""
        }
        return convertToMoneyFormat() + CoreUtilsKitLocalization.currency_unit.localized
    }
    
    func convertMoneyToNumber() -> Double {
        // Xử lý cả format mới (số nguyên như "100000") và format cũ (có thể có dấu phẩy, dấu chấm)
        // Loại bỏ tất cả ký tự không phải số và dấu chấm thập phân
        let cleanedString = self.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Nếu là số nguyên (không có dấu chấm), convert trực tiếp
        if !cleanedString.contains(".") {
            // Lấy tất cả chữ số
            let digits = cleanedString.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
            return Double(digits) ?? 0.0
        }
        
        // Nếu có dấu chấm thập phân, xử lý như số thập phân
        return Double(cleanedString) ?? 0.0
    }
    
    /// Format giá từ string bỏ .00 khi không cần thiết
    /// "100.00" → "100"
    /// "100.50" → "100.5"
    /// "27000000.00" → "27000000"
    func formatPriceWithoutTrailingZeros() -> String {
        // Convert string sang Double
        guard let doubleValue = Double(self) else {
            return self // Trả về nguyên bản nếu không parse được
        }
        
        // Sử dụng extension của Double
        return doubleValue.formattedWithoutTrailingZeros
    }
    
    func convertMoneyToNumberAsLong() -> Int64 {
        let number = components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
        let numberFormat = NumberFormatter()
        numberFormat.numberStyle = .decimal
        numberFormat.usesGroupingSeparator = false
        let output = "\(numberFormat.string(from: NSNumber(value: Double(number) ?? 0.0)) ?? "")".replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ".", with: "")
        return Int64(output) ?? 0
    }
    
    func normalizeVietnameseString() -> String {
        let originStr = self
//        CFStringNormalize((originStr as! CFMutableString), .D)
//        CFStringFold((originStr as! CFMutableString), .compareDiacriticInsensitive, nil)
        let finalString1 = originStr.replacingOccurrences(of: "đ", with: "d")
        let finalString2 = finalString1.replacingOccurrences(of: "Đ", with: "D")
        return finalString2
    }
    
    func isAlphaNumeric() -> Bool {
        let string = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 ")
        return trimmingCharacters(in: string) == ""
    }
	
	var isNumber: Bool {
		let digitsCharacters = CharacterSet(charactersIn: "0123456789")
		return CharacterSet(charactersIn: self).isSubset(of: digitsCharacters)
	}
    
    func isAlphaNumericAndCharacterSpecial() -> Bool {
        let string = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 .:-")
        return trimmingCharacters(in: string) == ""
    }
    
    func convertToContentMoneyTransfer() -> String {
        let okayChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890.-:")
        return self.filter {okayChars.contains($0) }
    }
}

// MARK: - String password
public extension String {
    func isPasswordSame() -> Bool {
        var check = true
        for charIndex in 0 ..< count - 1 {
            let start = index(startIndex, offsetBy: charIndex)
            let next = index(startIndex, offsetBy: charIndex + 1)
            if (self[start] != self[next]) {
                check = false
                break
            }
        }
        return check
    }
    
    func isPasswordIncreasing() -> Bool {
        var check = true
        for charIndex in 0 ..< count - 1 {
            let start = index(startIndex, offsetBy: charIndex)
            let next = index(startIndex, offsetBy: charIndex + 1)
            
            if let first = Int("\(self[start])"), let second = Int("\(self[next])") {
                if first + 1 != second {
                    check = false
                    break
                }
            }
        }
        return check
    }
    
    func replace(string:String, replacement:String) -> String {
        return self.replacingOccurrences(of: string, with: replacement, options: NSString.CompareOptions.literal, range: nil)
    }
}

// MARK: - String number
public extension String {
    var getNumeralsOnly: String {
        let pattern = UnicodeScalar("0")..."9"
        return String(unicodeScalars.compactMap { pattern ~= $0 ? Character($0) : nil })
    }
    
    func isNumeric() -> Bool {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.number(from: self)
        return number != nil
    }
    
    var floatValue: Float {
        return (self as NSString).floatValue
    }
}

// MARK: - String to phone number
public extension String {
    func getPhoneNumber() -> String {
        var phone = self
        
        let range = (phone as NSString).range(of: "(")
        if range.length > 0 {
            phone = (phone as NSString).substring(to: range.location)
        }
        
        phone = phone.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(separator: "")
        
        phone = phone.replacingOccurrences(of: " ", with: "")
        phone = phone.replacingOccurrences(of: "-", with: "")
        phone = phone.replacingOccurrences(of: "(", with: "")
        phone = phone.replacingOccurrences(of: ")", with: "")
        phone = phone.replacingOccurrences(of: "+", with: "")
        phone = phone.replacingOccurrences(of: ".", with: "")
        phone = phone.replacingOccurrences(of: "-", with: "")
        return phone
    }
    
    func phoneNotContent84() -> String {
        if self == Constant.applePhoneNumber {
            return Constant.applePhoneNumber
        }
        
        var phoneNumber = getPhoneNumber()
        if phoneNumber.count > 3 {
            if (((phoneNumber as NSString).substring(to: 2)) == "84") {
                phoneNumber = (phoneNumber as NSString).substring(from: 2)
                phoneNumber = "0\(phoneNumber)"
            }
        }
        return phoneNumber
    }
    
    func phoneContent84() -> String {
        if self == Constant.applePhoneNumber {
            return Constant.applePhoneNumber
        }
        
        var phoneNumber = getPhoneNumber()
        if phoneNumber.count > 3 {
            if !(((phoneNumber as NSString).substring(to: 2)) == "84") {
                phoneNumber = (phoneNumber as NSString).substring(from: 1)
                phoneNumber = "84\(phoneNumber)"
            }
        }
        return phoneNumber
    }
    
    func displayPhoneNumber() -> String {
        var phone = ""
        if !removeSpacing().isEmpty {
            phone = phoneNotContent84()
            if phone.count > 3 && phone.count < 7 {
                phone = "\((phone as NSString).substring(to: 3))-\((phone as NSString).substring(from: 3))"
            } else if phone.count >= 7 {
                phone = "\((phone as NSString).substring(with: NSRange(location: 0, length: phone.count - 6)))-\((phone as NSString).substring(with: NSRange(location: phone.count - 6, length: 3)))-\((phone as NSString).substring(from: phone.count - 3))" // swiftlint:disable:this line_length
            }
            
            return phone
        } else {
            return phone
        }
    }
    
    func avatarColor() -> UIColor { // swiftlint:disable:this cyclomatic_complexity
        if self == "" {
            return #colorLiteral(red: 0, green: 0.4901960784, blue: 0.8666666667, alpha: 1)
        }
        
        let char = self.prefix(1)
        switch char.uppercased() {
        case "A":
            return #colorLiteral(red: 1, green: 0.3921568627, blue: 0.3607843137, alpha: 1)
        case "B":
            return #colorLiteral(red: 1, green: 0.7450980392, blue: 0.2549019608, alpha: 1)
        case "C":
            return #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        case "D":
            return #colorLiteral(red: 0, green: 0.4901960784, blue: 0.8666666667, alpha: 1)
        case "E":
            return #colorLiteral(red: 0.09019607843, green: 0.6784313725, blue: 0.6901960784, alpha: 1)
        case "F":
            return #colorLiteral(red: 1, green: 0.3921568627, blue: 0.3607843137, alpha: 1)
        case "G":
            return #colorLiteral(red: 1, green: 0.7450980392, blue: 0.2549019608, alpha: 1)
        case "H":
            return #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        case "I":
            return #colorLiteral(red: 0, green: 0.4901960784, blue: 0.8666666667, alpha: 1)
        case "J":
            return #colorLiteral(red: 0.09019607843, green: 0.6784313725, blue: 0.6901960784, alpha: 1)
        case "K":
            return #colorLiteral(red: 1, green: 0.3921568627, blue: 0.3607843137, alpha: 1)
        case "L":
            return #colorLiteral(red: 1, green: 0.7450980392, blue: 0.2549019608, alpha: 1)
        case "M":
            return #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        case "N":
            return #colorLiteral(red: 0, green: 0.4901960784, blue: 0.8666666667, alpha: 1)
        case "O":
            return #colorLiteral(red: 0.09019607843, green: 0.6784313725, blue: 0.6901960784, alpha: 1)
        case "P":
            return #colorLiteral(red: 1, green: 0.3921568627, blue: 0.3607843137, alpha: 1)
        case "Q":
            return #colorLiteral(red: 1, green: 0.7450980392, blue: 0.2549019608, alpha: 1)
        case "R":
            return #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        case "S":
            return #colorLiteral(red: 0, green: 0.4901960784, blue: 0.8666666667, alpha: 1)
        case "T":
            return #colorLiteral(red: 0.09019607843, green: 0.6784313725, blue: 0.6901960784, alpha: 1)
        case "U":
            return #colorLiteral(red: 1, green: 0.3921568627, blue: 0.3607843137, alpha: 1)
        case "V":
            return #colorLiteral(red: 1, green: 0.7450980392, blue: 0.2549019608, alpha: 1)
        case "W":
            return #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        case "X":
            return #colorLiteral(red: 0, green: 0.4901960784, blue: 0.8666666667, alpha: 1)
        case "Y":
            return #colorLiteral(red: 0.09019607843, green: 0.6784313725, blue: 0.6901960784, alpha: 1)
        case "Z":
            return #colorLiteral(red: 1, green: 0.3921568627, blue: 0.3607843137, alpha: 1)
        default:
            return #colorLiteral(red: 1, green: 0.7450980392, blue: 0.2549019608, alpha: 1)
        }
    }
}

// MARK: - Standardize
public extension String {
    var withoutSpecialCharacters: String {
        return self.components(separatedBy: CharacterSet.symbols).joined(separator: "")
    }
    
    func removeDiacritics() -> String {
        return folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "đ", with: "d")
            .replacingOccurrences(of: "Đ", with: "D")
    }
    
    func convertToSearchValue() -> String {
        let characterSet = CharacterSet(charactersIn: "[ ]+-.")
        return removeDiacritics()
            .components(separatedBy: characterSet).joined(separator: "")
            .lowercased()
            .removeSpacing()
    }
    
    func convertToSearchValueNoti() -> String {
        let characterSet = CharacterSet(charactersIn: "+-.")
        
        let result = removeDiacritics().lowercased()
        
        let words = result.components(separatedBy: .whitespaces)
        let filteredWords = words.map { $0.components(separatedBy: characterSet).joined() }
        
        return filteredWords.joined(separator: " ")
    }

    func convertToSearchValueArray() -> [String] {
        let characterSet = CharacterSet(charactersIn: "[ ]+-.")

        var searchArray = removeDiacritics().components(separatedBy: characterSet)

        searchArray = searchArray.filter({ text in
            return !text.isEmpty
        })

        return searchArray.map { $0.lowercased() }
    }
    
    func convertTime(fromDateFormat fromDateFormate: String, toDateFormat: String) -> String? {
        let df = DateFormatter()
        let posix = NSLocale(localeIdentifier: "en_US_POSIX")
        let destinationTimeZone = NSTimeZone.system as NSTimeZone
        df.timeZone = destinationTimeZone as TimeZone
        df.dateFormat = fromDateFormate
        df.locale = posix as Locale
        df.calendar = Calendar(identifier: .gregorian)
        let date = df.date(from: self)
        df.dateFormat = toDateFormat
        
        if let date = date {
            return df.string(from: date)
        }
        return nil
    }
    
    func convertTimePlusOneMinus(fromDateFormat fromDateFormate: String, toDateFormat: String) -> String? {
        let df = DateFormatter()
        let posix = NSLocale(localeIdentifier: "en_US_POSIX")
        let destinationTimeZone = NSTimeZone.system as NSTimeZone
        df.timeZone = destinationTimeZone as TimeZone
        df.dateFormat = fromDateFormate
        df.locale = posix as Locale
        df.calendar = Calendar(identifier: .gregorian)
        let date = df.date(from: self)
        df.dateFormat = toDateFormat
        
        if var date = date {
            date.addTimeInterval(TimeInterval(60.0))
            return df.string(from: date)
        }
        return nil
    }
}

// MARK: - Rect
public extension String {
    func height(withWidth width: CGFloat, font: UIFont) -> CGFloat {
        let maxSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let actualSize = self.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil)
        return actualSize.height
    }

    func width(withFont font: UIFont?) -> CGFloat {
        if let customFont = font {
            let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: customFont]
            let size = (self as NSString).size(withAttributes: attributes)

            return size.width
        }

        return 0.0
    }
}

// MARK: - Spacing text
public extension String {
    func spacingText(_ spacing: CGFloat = 4.0) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = spacing
        let attrString = NSMutableAttributedString(string: self)
        attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrString.length))
        return attrString
    }
}

// MARK: - Error
extension String: Error {}

// MARK: - Card Format
public extension String {
    func cardShort() -> String {
        return count >= 4 ? "...\(self[index(endIndex, offsetBy: -4)])" : self
    }
}

// MARK: - AES Encrypt
//public extension String {
//    func aesECBEncrypt(_ key: String) -> String {
//        do {
//            let aes = try AES(key: key)
//            let encryptedData: Data = try aes.encrypt(self)
//            return encryptedData.base64EncodedString()
//        } catch {
//            print("Something went wrong: \(error)")
//        }
//        
//        return ""
//    }
//
//    func hmacEncrypt() -> String {
//        guard let messageData = self.data(using:String.Encoding.utf8) else { return "" }
//        var digestData = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
//        _ = digestData.withUnsafeMutableBytes { (digestBytes) -> Bool in
//            messageData.withUnsafeBytes({ (messageBytes) -> Bool in
//                _ = CC_SHA256(messageBytes.baseAddress, CC_LONG(messageData.count),
//                              digestBytes.bindMemory(to: UInt8.self).baseAddress)
//                return true
//            })
//        }
//
//        return digestData.map { String(format: "%02hhx", $0) }.joined()
//    }
//    
//    func sha256() -> String {
//        let data = Data(utf8)
//        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
//        data.withUnsafeBytes { buffer in
//          _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
//        }
//        return hash.map { String(format: "%02hhx", $0) }.joined()
//    }
//}

// MARK: - Standardize Name
public extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    func standardizeName() -> String {
        let content = self.lowercased()
        let subs: [Substring] = content.split(separator: " ")
        var standardizeString: String = ""
        for sub in subs {
            let realString = String(sub).capitalizingFirstLetter()
            standardizeString.append(realString)
            standardizeString.append(" ")
        }
        return standardizeString.trim()
    }
}

// String Attributed
public extension String {
    func bold(range: String, font: UIFont, color: UIColor = UIColor(hex: "#222222")) -> NSMutableAttributedString {
        let range = (self as NSString).range(of: range)
        let attributed = NSMutableAttributedString(string: self)
        
        attributed.addAttribute(NSAttributedString.Key.font, value: font, range: range)
        attributed.addAttribute(.foregroundColor, value: color, range: range)
        
        return attributed
    }
    
    func boldAttributed(boldStrings: [String],
                        font: UIFont,
                        fontBold: UIFont? = nil,
                        color: UIColor = UIColor(hex: "4E4E4E"),
                        boldColor: UIColor = UIColor(hex: "4E4E4E")) -> NSMutableAttributedString {
        let attString = NSMutableAttributedString(string: self, attributes: [.font: font, .foregroundColor: color])
        for boldString in boldStrings {
            if let boldRank = self.range(of: boldString) {
                attString.addAttributes([.font: fontBold != nil ? fontBold! : UIFont.systemFont(ofSize: font.pointSize, weight: .bold),
                                         .foregroundColor: boldColor],
                                        range: NSRange(boldRank, in: self))
            }
        }
        return attString
    }

    var convertHtmlToNSAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else {
            return nil
        }
        do {
            return try NSAttributedString(data: data,
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: nil)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }

    func convertHtmlToAttributedString(fontSize: String, csscolor: String = "#222222") -> NSAttributedString? {
        let modifiedString = "<style>body{font-family: 'SF Pro Display'; font-size:\(fontSize)px; color: \(csscolor);}</style>\(self)"
        guard let data = modifiedString.data(using: .utf8) else {
            return nil
        }
        do {
            return try NSAttributedString(data: data,
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: nil)
        } catch {
            print(error)
            return nil
        }
    }
}

// Substring
public extension String {
    func index(from: Int) -> Index {
        return self.index(startIndex, offsetBy: from)
    }

    func substring(from: Int) -> String {
        if from > self.count {
            return ""
        }
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func substring(to: Int) -> String {
        if to > self.count {
            return self
        }
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }

    func substring(with range: Range<Int>) -> String {
        let startIndex = index(from: range.lowerBound)
        let endIndex = index(from: range.upperBound)
        return String(self[startIndex..<endIndex])
    }
    
    func firstCharacterUpperCase() -> String? {
        guard !isEmpty else {
			return nil
		}
        let lowerCasedString = self.lowercased()
        return lowerCasedString.replacingCharacters(in: lowerCasedString.startIndex...lowerCasedString.startIndex, with: String(lowerCasedString[lowerCasedString.startIndex]).uppercased())
    }
    
    func replaceFirstOccurrence(of target: String, with replacement: String) -> String {
        guard let range = self.range(of: target) else { return self }
        return self.replacingCharacters(in: range, with: replacement)
    }
}
