//
//  AccountObject.swift
//  ECommerce
//
//  Created by wizard.os25 on 18/11/25.
//


import Foundation

extension NSObject {
    func toJsonString() -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self,
                                                      options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}

extension Encodable {
    func toJsonString(_ encoder: JSONEncoder = JSONEncoder()) -> String {
        do {
            let data = try encoder.encode(self)
            let result = String(decoding: data, as: UTF8.self)
            return result
        } catch {
            return ""
        }
    }
}

public extension Encodable {
//    func toDictionary(_ encoder: JSONEncoder = JSONEncoder()) -> [String: Any] {
//        do {
//            let data = try encoder.encode(self)
//            let object = try JSONSerialization.jsonObject(with: data)
//            guard let json = object as? [String: Any] else {
//                let context = DecodingError.Context(codingPath: [], debugDescription: "Deserialized object is not a dictionary")
//                throw DecodingError.typeMismatch(type(of: object), context)
//            }
//            return json
//        } catch {
//            return [:]
//        }
//    }
}
