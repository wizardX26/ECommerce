//
//  LocationData.swift
//  ECommerce
//
//  Created by wizard.os25 on 11/1/26.
//

import Foundation

// MARK: - Location Data Models

public struct LocationItem {
    public let id: Int
    public let name: String
    
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - Location Data Constants (Based on Seeder)

public struct LocationData {
    
    // MARK: - Country
    public static let vietnam = LocationItem(id: 1, name: "Việt Nam")
    
    // MARK: - Province
    public static let haNoi = LocationItem(id: 2, name: "Hà Nội")
    
    // MARK: - Districts
    public static let districts: [LocationItem] = [
        LocationItem(id: 3, name: "Hoàn Kiếm"),
        LocationItem(id: 4, name: "Ba Đình"),
        LocationItem(id: 5, name: "Đống Đa"),
        LocationItem(id: 6, name: "Hai Bà Trưng"),
        LocationItem(id: 7, name: "Cầu Giấy"),
        LocationItem(id: 8, name: "Thanh Xuân"),
        LocationItem(id: 9, name: "Hoàng Mai"),
        LocationItem(id: 10, name: "Long Biên")
    ]
    
    // MARK: - Wards by District
    public static let wardsByDistrict: [Int: [LocationItem]] = [
        // Hoàn Kiếm (district_id = 3)
        3: [
            LocationItem(id: 11, name: "Hàng Trống"),
            LocationItem(id: 12, name: "Hàng Bông"),
            LocationItem(id: 13, name: "Hàng Đào"),
            LocationItem(id: 14, name: "Cửa Đông"),
            LocationItem(id: 15, name: "Lý Thái Tổ")
        ],
        // Ba Đình (district_id = 4)
        4: [
            LocationItem(id: 21, name: "Phúc Xá"),
            LocationItem(id: 22, name: "Trúc Bạch"),
            LocationItem(id: 23, name: "Vĩnh Phúc"),
            LocationItem(id: 24, name: "Cống Vị"),
            LocationItem(id: 25, name: "Liễu Giai")
        ],
        // Đống Đa (district_id = 5)
        5: [
            LocationItem(id: 31, name: "Láng Hạ"),
            LocationItem(id: 32, name: "Láng Thượng"),
            LocationItem(id: 33, name: "Khâm Thiên"),
            LocationItem(id: 34, name: "Thổ Quan"),
            LocationItem(id: 35, name: "Nam Đồng")
        ],
        // Hai Bà Trưng (district_id = 6)
        6: [
            LocationItem(id: 41, name: "Nguyễn Du"),
            LocationItem(id: 42, name: "Bạch Đằng"),
            LocationItem(id: 43, name: "Phạm Đình Hổ"),
            LocationItem(id: 44, name: "Bùi Thị Xuân")
        ],
        // Cầu Giấy (district_id = 7)
        7: [
            LocationItem(id: 51, name: "Nghĩa Tân"),
            LocationItem(id: 52, name: "Nghĩa Đô"),
            LocationItem(id: 53, name: "Mai Dịch"),
            LocationItem(id: 54, name: "Dịch Vọng")
        ],
        // Thanh Xuân (district_id = 8)
        8: [
            LocationItem(id: 61, name: "Khương Trung"),
            LocationItem(id: 62, name: "Khương Mai"),
            LocationItem(id: 63, name: "Thanh Xuân Trung")
        ],
        // Hoàng Mai (district_id = 9)
        9: [
            LocationItem(id: 71, name: "Giáp Bát"),
            LocationItem(id: 72, name: "Vĩnh Hưng"),
            LocationItem(id: 73, name: "Định Công")
        ],
        // Long Biên (district_id = 10)
        10: [
            LocationItem(id: 81, name: "Gia Thụy"),
            LocationItem(id: 82, name: "Ngọc Lâm"),
            LocationItem(id: 83, name: "Phúc Lợi")
        ]
    ]
    
    // MARK: - Helper Methods
    
    public static func getWards(for districtId: Int) -> [LocationItem] {
        return wardsByDistrict[districtId] ?? []
    }
    
    public static func getDistrict(by id: Int) -> LocationItem? {
        return districts.first { $0.id == id }
    }
    
    public static func getWard(by id: Int, in districtId: Int) -> LocationItem? {
        return getWards(for: districtId).first { $0.id == id }
    }
}
