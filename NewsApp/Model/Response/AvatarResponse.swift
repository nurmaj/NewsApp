//
//  AvatarResponse.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 30/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
struct AvatarResponse: BasicResponse {
    var success: Bool
    var message: String?
    var avatar: ImageItem?
}
extension AvatarResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case success, message, avatar
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        success = try values.decode(Bool.self, forKey: .success)
        message = try values.decodeIfPresent(String.self, forKey: .message)
        avatar = try values.decodeIfPresent(ImageItem.self, forKey: .avatar)
    }
}
