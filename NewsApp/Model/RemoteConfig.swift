//
//  RemoteConfig.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 22/2/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

struct RemoteConfig {
    let key: String
    let tabItems: [TabItem]
    let subscription: SubscriptionConfig?
}
extension RemoteConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case key="set_key", tabItems="tabs", subscription
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key = try values.decode(String.self, forKey: .key)
        tabItems = try values.decode([TabItem].self, forKey: .tabItems)
        subscription = try values.decodeIfPresent(SubscriptionConfig.self, forKey: .subscription)
    }
    /*func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(tabItem, forKey: .tabItem)
        try container.encodeIfPresent(subsription, forKey: .subsription)
    }*/
}
struct SubscriptionConfig {
    let buyOrSubscribeAction: String
    let successUrl: String
    let failureUrl: String
    let contacts: [ContactItem]?
    
    enum SubscriptionResult {
        case none, paymentFailed, paymentSuccess, paymentVerifyFailed, paymentVerifySuccess
    }
}
typealias SubscriptionState = SubscriptionConfig.SubscriptionResult
extension SubscriptionConfig: Codable {
    enum CodingKeys: String, CodingKey {
        case buyOrSubscribeAction="buy_or_subscribe", successUrl="success_url", failureUrl="failure_url", contacts
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        buyOrSubscribeAction = try values.decode(String.self, forKey: .buyOrSubscribeAction)
        successUrl = try values.decode(String.self, forKey: .successUrl)
        failureUrl = try values.decode(String.self, forKey: .failureUrl)
        contacts = try values.decodeIfPresent([ContactItem].self, forKey: .contacts)
    }
}
