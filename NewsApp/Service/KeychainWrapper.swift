//
//  KeychainWrapper.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 20/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
class KeychainWrapper {
    func storeInternetAccountFor(account: String, server: String, user: Account) throws {
        guard let userData = try? JSONEncoder().encode(user) else { throw KeychainError.unexpectedData }
        
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: account,
                                    kSecAttrServer as String: server,
                                    kSecValueData as String: userData]
        let status = SecItemAdd(query as CFDictionary, nil)
        //guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
        switch status {
        case errSecSuccess:
            break
        case errSecDuplicateItem: // Consider updating current Account
            try updateInternetAccountFor(account: account, server: server, user: user)
            break
        default:
            throw KeychainError.unableToStore
        }
    }
    func updateInternetAccountFor(account: String, server: String, user: Account) throws {
        guard let userData = try? JSONEncoder().encode(user) else { throw KeychainError.unexpectedData }
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: account,
                                    kSecAttrServer as String: server]
        let attributes: [String: Any] = [
            kSecValueData as String: userData
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status != errSecItemNotFound else { throw KeychainError.itemNotFound }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }
    }
    func getStoredUserFor(server: String) throws -> Account? {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        /*guard status != errSecItemNotFound else { throw KeychainError.itemNotFound }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }*/
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess else { return nil }
        guard let existingItem = item as? [String : Any],
            let storedData = existingItem[kSecValueData as String] as? Data,
            //let password = String(data: passwordData, encoding: String.Encoding.utf8),
            let account = try? JSONDecoder().decode(Account.self, from: storedData)//,
            //let accountEmail = existingItem[kSecAttrAccount as String] as? String
        else {
            return nil
            //throw KeychainError.unexpectedPasswordData
        }
        return account
        //let credentials = Credentials(username: account, password: password)
    }
    func deleteInternetAccountFor(account: String, server: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: account,
                                    kSecAttrServer as String: server]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }
    func remoteAccountExists(server: String) throws -> Bool {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        /*guard status != errSecItemNotFound else { throw KeychainError.itemNotFound }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status) }*/
        return status == errSecSuccess
    }
}
enum KeychainError: Error {
    case itemNotFound
    case unexpectedData
    case unableToStore
    case unableToDelete
    case unhandledError(status: OSStatus)
}
