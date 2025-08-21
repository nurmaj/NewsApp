//
//  PushNotItem.swift
//  NewsApp
//
//  Created by Nurmat Junusov. on 10/12/22.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

struct PushNotItem {
    var newsItem: NewsItem?
    var linkItem: PushLinkItem?
}

extension PushNotItem: Decodable {
    enum CodingKeys: String, CodingKey {
        case newsItem="type1", linkItem="type2"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        newsItem = try values.decodeIfPresent(NewsItem.self, forKey: .newsItem)
        linkItem = try values.decodeIfPresent(PushLinkItem.self, forKey: .linkItem)
    }
}
/*extension PushNotItem: Encodable {
    
}*/
extension PushNotItem {
    init(newsItem: NewsItem) {
        self.newsItem = newsItem
    }
}

extension PushNotItem {
    init(linkItem: PushLinkItem) {
        self.linkItem = linkItem
    }
}

typealias AppPushNotType = PushNotItem.CodingKeys

struct PushLinkItem: Decodable {
    var link: URL?
    enum CodingKeys: String, CodingKey {
        case link="ios_link"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        link = try values.decodeIfPresent(URL.self, forKey: .link)
    }
}
