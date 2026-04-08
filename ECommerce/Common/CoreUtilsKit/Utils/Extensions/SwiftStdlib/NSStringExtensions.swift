//
//  NSStringExtensions.swift
//  CoreUtilsKit
//
//  Created by Bui Thien Thien on 2/2/21.
//  Copyright © 2021 ViettelPay App Team. All rights reserved.
//

import Foundation

public extension NSString {
    @objc var standardizeName: NSString {
        let content: String = self as String
        return content.standardizeName() as NSString
    }
}
