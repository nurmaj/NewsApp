//
//  PollResponse.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 21/1/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
struct PollResponse: BasicResponse {
    var success: Bool
    var message: String?
    
    var pollItem: PollItem?
}
extension PollResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case success, message="msg", pollItem="poll"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        success = try values.decode(Bool.self, forKey: .success)
        message = try values.decodeIfPresent(String.self, forKey: .message)
        pollItem = try values.decodeIfPresent(PollItem.self, forKey: .pollItem)
    }
}
