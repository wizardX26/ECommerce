//
//  EncodableExtensions.swift
//  CoreUtilsKit
//
//  Created by Bui Thien Thien on 11/4/20.
//  Copyright © 2020 ViettelPay App Team. All rights reserved.
//

import Foundation

public extension Encodable {
    func toDictionary(_ encoder: JSONEncoder = JSONEncoder()) -> [String: Any] {
        do {
            let data = try encoder.encode(self)
            let object = try JSONSerialization.jsonObject(with: data)
            guard let json = object as? [String: Any] else {
                let context = DecodingError.Context(codingPath: [], debugDescription: "Deserialized object is not a dictionary")
                throw DecodingError.typeMismatch(type(of: object), context)
            }
            return json
        } catch {
            return [:]
        }
    }
}
