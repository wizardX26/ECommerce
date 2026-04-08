//
//  LocationList.swift
//  ECommerce
//
//  Created by wizard.os25 on 13/1/26.
//

import Foundation

public struct LocationList {
    public let addresses: [Address]
    
    public init(addresses: [Address]) {
        self.addresses = addresses
    }
}
