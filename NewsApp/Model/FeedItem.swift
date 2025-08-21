//
//  FeedItem.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 29/11/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

struct FeedItem: Identifiable {
    let id, title: String
    let secondaryId = UUID().uuidString
    let type: FeedType?
    var newsItem: NewsItem?
    var adItem: AdItem?
    var pollItem: PollItem?
}
extension FeedItem: Hashable {
    static func == (lhs: FeedItem, rhs: FeedItem) -> Bool {
        return lhs.id == rhs.id &&
            lhs.secondaryId == rhs.secondaryId &&
            lhs.title.count == rhs.title.count &&
            lhs.type == rhs.type &&
            /* MARK: NewsItem */
            lhs.newsItem?.id == rhs.newsItem?.id &&
            lhs.newsItem?.redirectUrl == rhs.newsItem?.redirectUrl &&
            lhs.newsItem?.onlineNum == rhs.newsItem?.onlineNum &&
            lhs.newsItem?.closedStatus == rhs.newsItem?.closedStatus &&
            lhs.newsItem?.views == rhs.newsItem?.views &&
            lhs.newsItem?.timestamp == rhs.newsItem?.timestamp &&
            lhs.newsItem?.datePublished == rhs.newsItem?.datePublished &&
            lhs.newsItem?.displayType == rhs.newsItem?.displayType &&
            lhs.newsItem?.image?.outer?.id == rhs.newsItem?.image?.outer?.id &&
            lhs.newsItem?.image?.outer?.thumb == rhs.newsItem?.image?.outer?.thumb &&
            /* MARK: AdItem */
            lhs.adItem?.id == rhs.adItem?.id &&
            lhs.adItem?.hashId == rhs.adItem?.hashId &&
            lhs.adItem?.target == rhs.adItem?.target &&
            lhs.adItem?.url == rhs.adItem?.url &&
            lhs.adItem?.bannerPath == rhs.adItem?.bannerPath &&
            lhs.adItem?.bgColor == rhs.adItem?.bgColor &&
            lhs.adItem?.showedTime == rhs.adItem?.showedTime &&
            lhs.adItem?.adIds == rhs.adItem?.adIds &&
            lhs.adItem?.type == rhs.adItem?.type &&
            lhs.adItem?.bannerPathLandscape == rhs.adItem?.bannerPathLandscape &&
            /* MARK: PollItem */
            lhs.pollItem?.id == rhs.pollItem?.id &&
            lhs.pollItem?.title.count == rhs.pollItem?.title.count
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(secondaryId)
        hasher.combine(title.count)
        hasher.combine(type)
        hasher.combine(newsItem?.id)
        hasher.combine(newsItem?.redirectUrl)
        hasher.combine(newsItem?.onlineNum)
        hasher.combine(newsItem?.closedStatus)
        hasher.combine(newsItem?.views)
        hasher.combine(newsItem?.timestamp)
        hasher.combine(newsItem?.datePublished)
        hasher.combine(newsItem?.displayType)
        hasher.combine(newsItem?.image?.outer?.id)
        hasher.combine(newsItem?.image?.outer?.thumb)
        hasher.combine(adItem?.id)
        hasher.combine(adItem?.hashId)
        hasher.combine(adItem?.target)
        hasher.combine(adItem?.url)
        hasher.combine(adItem?.bannerPath)
        hasher.combine(adItem?.bgColor)
        hasher.combine(adItem?.showedTime)
        hasher.combine(adItem?.adIds)
        hasher.combine(adItem?.type)
        hasher.combine(adItem?.bannerPathLandscape)
        hasher.combine(pollItem?.id)
        hasher.combine(pollItem?.title.count)
    }
}
extension FeedItem: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, title, type="special_type"
        case newsItem, adItem, pollItem
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.type = try container.decodeIfPresent(FeedType.self, forKey: .type)
        switch type {
        case .ad:
            self.adItem = try? AdItem(from: decoder)
            break
        case .poll:
            self.pollItem = try? PollItem(from: decoder)
            break
        default:// News Item
            self.newsItem = try NewsItem(from: decoder)
            break
        }
    }
}
extension FeedItem {
    init(newsItem: NewsItem) {
        self.id = newsItem.id
        self.title = newsItem.title
        self.type = .newsItem
        self.newsItem = newsItem
    }
    func redirectable() -> Bool {
        return newsItem?.redirectUrl != nil
    }
}
extension FeedItem {
    init(pollItem: PollItem) {
        self.id = pollItem.id
        self.title = pollItem.title
        self.type = .poll
        self.pollItem = pollItem
    }
}
struct FeedItemDetail {
    var item: FeedItem
    var position: Int
}
extension FeedItemDetail: Hashable {
    static func == (lhs: FeedItemDetail, rhs: FeedItemDetail) -> Bool {
        return lhs.item == rhs.item &&
            lhs.position == rhs.position
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(item)
        hasher.combine(position)
    }
}
enum FeedLayout: String, Codable {
    case large, small
}
enum FeedType: String, Decodable {
    case ad, poll, newsItem="news_item"
}
enum PhraseType: String {
    case search, tag
}
