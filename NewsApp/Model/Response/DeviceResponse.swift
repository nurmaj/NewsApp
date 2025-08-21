//
//  DeviceResponse.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 12/1/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
struct DeviceResponse: BasicResponse {
    var success: Bool
    var message: String?
    let newToken: String?
    let newDeviceId: Int?
    let remoteDate: String?
    let config: RemoteConfig?
}
extension DeviceResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case success, message, newToken="new_token", newDeviceId="ned", remoteDate="server_date", config
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        success = try values.decode(Bool.self, forKey: .success)
        message = try values.decodeIfPresent(String.self, forKey: .message)
        newToken = try values.decodeIfPresent(String.self, forKey: .newToken)
        newDeviceId = try values.decodeIfPresent(Int.self, forKey: .newDeviceId)
        remoteDate = try values.decodeIfPresent(String.self, forKey: .remoteDate)
        config = try values.decodeIfPresent(RemoteConfig.self, forKey: .config)
    }
}
