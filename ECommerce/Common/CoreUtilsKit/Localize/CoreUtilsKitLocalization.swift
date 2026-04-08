

import Foundation

public enum CoreUtilsKitLocalization: String {
    case currency_unit
    case currency_thousand
    case currency_million
    case currency_billion
    case point_unit
    case required_touch_id
    case required_face_id
    
    public var localized: String {
        return rawValue.localized(using: "")
    }
}

