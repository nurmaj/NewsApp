//
//  NewsSubscription.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 11/2/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
struct NewsSubscription {
    let text: String
    let packages: [SubscriptionPackage]
    let contactText: String
}
extension NewsSubscription: Decodable, Hashable {
    enum CodingKeys: String, CodingKey {
        case text, packages, contactText="contact_text"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        text = try values.decode(String.self, forKey: .text)
        packages = try values.decode([SubscriptionPackage].self, forKey: .packages)
        contactText = try values.decode(String.self, forKey: .contactText)
    }
    static func == (lhs: NewsSubscription, rhs: NewsSubscription) -> Bool {
        return lhs.text == rhs.text &&
            lhs.packages == rhs.packages &&
            lhs.contactText == rhs.contactText
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(packages)
        hasher.combine(contactText)
    }
}
extension NewsSubscription {
    struct Package: Identifiable, Decodable, Hashable {
        var id: String
        let name: String
        let price: String
        let priceNum: Int
        let subscribe: Subscribe
        enum CodingKeys: String, CodingKey {
            case id, name, price, priceNum="price_num", subscribe
        }
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            id = try values.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
            name = try values.decode(String.self, forKey: .name)
            price = try values.decode(String.self, forKey: .price)
            priceNum = try values.decode(Int.self, forKey: .priceNum)
            subscribe = try values.decode(Subscribe.self, forKey: .subscribe)
        }
        static func == (lhs: SubscriptionPackage, rhs: SubscriptionPackage) -> Bool {
            return lhs.id == rhs.id &&
                lhs.name == rhs.name &&
                lhs.price == rhs.price &&
                lhs.subscribe == rhs.subscribe
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(name)
            hasher.combine(price)
            hasher.combine(subscribe)
        }
    }
    struct Subscribe: Decodable, Hashable {
        let title: String
        let url: URL?
        enum CodingKeys: String, CodingKey {
            case title, url
        }
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            title = try values.decode(String.self, forKey: .title)
            url = try values.decodeIfPresent(URL.self, forKey: .url)
        }
        static func == (lhs: NewsSubscribe, rhs: NewsSubscribe) -> Bool {
            return lhs.title == rhs.title &&
                lhs.url == rhs.url
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(url)
        }
    }
}
typealias SubscriptionPackage = NewsSubscription.Package
typealias NewsSubscribe = NewsSubscription.Subscribe
