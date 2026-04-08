//
//  UserResponseStorage.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

protocol UserResponseStorage {
    func save(user: User, completion: @escaping (Result<Void, Error>) -> Void)
    func getUser(completion: @escaping (Result<User?, Error>) -> Void)
    func clear(completion: @escaping (Result<Void, Error>) -> Void)
}
