//
//  AccountResponse.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 20/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
struct AccountResponse {
    let success: Bool
    let message: String?
    let user: Account?
}
extension AccountResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case success, message, user
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        success = try values.decode(Bool.self, forKey: .success)
        message = try values.decodeIfPresent(String.self, forKey: .message)
        user = try values.decodeIfPresent(Account.self, forKey: .user)
    }
}
