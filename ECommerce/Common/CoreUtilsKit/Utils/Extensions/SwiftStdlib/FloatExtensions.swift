import Foundation

public extension Float {
    func toMoneyPostfix(places: Int) -> (value: Float, valueShow: String) {
        switch self {
        case 1...999999:
            return toValuePostFix(unit: 1000, unitStr: CoreUtilsKitLocalization.currency_thousand.localized, places: 0)
        case 1000000...99999999:
            return toValuePostFix(unit: 1000000, unitStr: CoreUtilsKitLocalization.currency_million.localized, places: places)
        case 1000000000...99999999999:
            return toValuePostFix(unit: 1000000000, unitStr: CoreUtilsKitLocalization.currency_billion.localized, places: places)
        default:
            return (self, String(Int(self)))
        }
    }
    
    func toValuePostFix(unit: Float = 1, unitStr: String = "", places: Int) -> (value: Float, valueShow: String) {
        let value = Float(self / unit).roundTo(places)
        return (value * unit, String(format: "%.\(places)f%@", value, unitStr))
    }
    
    func roundTo(_ places: Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
    
    func toString(decimal: Int = 9) -> String {
            let value = decimal < 0 ? 0 : decimal
            var string = String(format: "%.\(value)f", self)

            while string.last == "0" || string.last == "." {
                if string.last == "." {
                    string = String(string.dropLast())
                    break
                }
                string = String(string.dropLast())
            }
            return string
    }
}
