//
//  AccountService.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 20/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

struct AccountService {
    let kcw = KeychainWrapper()
    func storeRemoteUser(_ account: Account, result: @escaping (Bool) -> Void) {
        do {
            try self.kcw.storeInternetAccountFor(account: account.email, server: API.Endpoint.projectHost, user: account)
            result(true)
        } catch {
            result(false)
        }
    }
    func getStoredUser() -> Account? {
        do {
            let account = try kcw.getStoredUserFor(server: API.Endpoint.projectHost)
            return account
        } catch {
            return nil
        }
    }
    func logoutStoredUser(account: String) -> Bool {
        do {
            try kcw.deleteInternetAccountFor(account: account, server: API.Endpoint.projectHost)
            return true
        } catch {
            return false
        }
    }
}
