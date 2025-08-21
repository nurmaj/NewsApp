//
//  AccountUrlResponse.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 8/11/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

struct AccountUrlResponse: BasicResponse {
    var success: Bool
    var message: String?
    
    let url: URL?
}
extension AccountUrlResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case success, message, url
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        success = try values.decode(Bool.self, forKey: .success)
        message = try values.decodeIfPresent(String.self, forKey: .message)
        url = try values.decodeIfPresent(URL.self, forKey: .url)
    }
}
