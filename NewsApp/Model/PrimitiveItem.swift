//
//  PrimitiveItem.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 2/3/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

struct PrimitiveItem {
    let title: String
    let url: URL?
    let label, date: String?
    let type: String? // {pre, post, nil}
}

extension PrimitiveItem: Decodable {
    enum CodingKeys: String, CodingKey {
        case url, title, label, type
        case date = "formatted_date"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        title = try values.decode(String.self, forKey: .title)
        url = try values.decodeIfPresent(URL.self, forKey: .url)
        label = try values.decodeIfPresent(String.self, forKey: .label)
        date = try values.decodeIfPresent(String.self, forKey: .date)
        type = try values.decodeIfPresent(String.self, forKey: .type)
    }
}
extension PrimitiveItem: Hashable {
    static func == (lhs: PrimitiveItem, rhs: PrimitiveItem) -> Bool {
        return lhs.title == rhs.title &&
            lhs.url == rhs.url &&
            lhs.label == rhs.label &&
            lhs.date == rhs.date &&
            lhs.type == rhs.type
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(url)
        hasher.combine(label)
        hasher.combine(date)
        hasher.combine(type)
    }
}
