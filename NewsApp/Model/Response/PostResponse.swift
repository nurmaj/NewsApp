//
//  PostResponse.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 9/11/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

struct PostResponse {
    let success: Bool
    let message: String?
}
extension PostResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case success, message
    }
    enum AlternateCodingKeys: String, CodingKey {
        case msg = "msg"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let alternateValues = try decoder.container(keyedBy: AlternateCodingKeys.self)
        self.success = try values.decode(Bool.self, forKey: .success)
        if alternateValues.contains(.msg) {
            self.message = try alternateValues.decodeIfPresent(String.self, forKey: .msg)
        } else {
            self.message = try values.decodeIfPresent(String.self, forKey: .message)
        }
    }
}
