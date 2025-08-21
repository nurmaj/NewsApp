//
//  PollItem.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 30/11/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
struct PollItem: Identifiable {
    let id: String
    let title: String
    let title2: String?
    let short: String?
    let text: String
    let icon: IconType?
    var date: String
    let url: URL?
    let displayType: FeedLayout?
    let startDate: String?
    let endDate: String?
    let endDateISO: String?
    let newsId: String?
    var views: String?
    var comments: Int?
    
    var selectedVoteId: String?
    var canVote: Bool
    var anonymousVoting: Bool
    var hideResult: Bool?
    let image: ImageItem?
    let infoMsg: String?
    let newsUrl: URL?
    let authMsg: String?
    let totalVotes: Int
    let options: [PollOptionItem]
}
extension PollItem: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, title, title2="web_title", short="short_text", text, icon, date, url, startDate="start_date", endDate="till_date", endDateISO="till_date_iso", newsId="pnid", views="cnt_view", comments="cnt_comm", selectedVoteId="vote_id", canVote="can_vote", anonymousVoting="no_auth", hideResult="hide_result", image, infoMsg="info_msg", newsUrl="info_url", authMsg="auth_msg", totalVotes="total_votes", options="params", displayType="display_type"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        title2 = try container.decodeIfPresent(String.self, forKey: .title2)
        short = try container.decodeIfPresent(String.self, forKey: .short)
        text = try container.decode(String.self, forKey: .text)
        icon = try container.decodeIfPresent(IconType.self, forKey: .icon)
        date = try container.decode(String.self, forKey: .date)
        url = try container.decodeIfPresent(URL.self, forKey: .url)
        displayType = try container.decodeIfPresent(FeedLayout.self, forKey: .displayType)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        endDateISO = try container.decodeIfPresent(String.self, forKey: .endDateISO)
        newsId = try container.decodeIfPresent(String.self, forKey: .newsId)
        if let viewStr = try? container.decodeIfPresent(String.self, forKey: .views) {
            views = viewStr
        } else if let viewNum = try? container.decodeIfPresent(Int.self, forKey: .views) {
            views = String(viewNum)
        }
        if let commNum = try? container.decodeIfPresent(Int.self, forKey: .comments) {
            comments = commNum
        } else if let commStr = try? container.decodeIfPresent(String.self, forKey: .comments) {
            comments = Int(commStr)
        }
        selectedVoteId = try container.decodeIfPresent(String.self, forKey: .selectedVoteId)
        canVote = try container.decode(Bool.self, forKey: .canVote)
        anonymousVoting = try container.decodeIfPresent(Bool.self, forKey: .anonymousVoting) ?? true
        if let hideResultStr = try? container.decodeIfPresent(String.self, forKey: .hideResult) {
            hideResult = hideResultStr == "1"
        } else if let hideResultNum = try? container.decodeIfPresent(Int.self, forKey: .hideResult) {
            hideResult =  hideResultNum == 1
        }
        image = try container.decodeIfPresent(ImageItem.self, forKey: .image)
        infoMsg = try container.decodeIfPresent(String.self, forKey: .infoMsg)
        newsUrl = try container.decodeIfPresent(URL.self, forKey: .newsUrl)
        authMsg = try container.decodeIfPresent(String.self, forKey: .authMsg)
        totalVotes = try container.decode(Int.self, forKey: .totalVotes)
        options = try container.decode([PollOptionItem].self, forKey: .options)
    }
}
extension PollItem: Hashable {
    static func == (lhs: PollItem, rhs: PollItem) -> Bool {
        return lhs.id == rhs.id &&
            lhs.title == rhs.title &&
            lhs.text == rhs.text &&
            lhs.date == rhs.date &&
            lhs.views == rhs.views &&
            lhs.image == rhs.image &&
            lhs.totalVotes == rhs.totalVotes &&
            lhs.options == rhs.options
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(text)
        hasher.combine(date)
        hasher.combine(views)
        hasher.combine(image)
        hasher.combine(totalVotes)
        hasher.combine(options)
    }
}
extension PollItem {
    struct Option: Identifiable {
        let id: String
        let title: String
        let num: Int
        let percent: String
    }
    enum IconType: String, Decodable {
        case checkmark="check", circlemark="radio"
    }
}
extension PollOptionItem: Decodable, Hashable {
    enum CodingKeys: String, CodingKey {
        case id="item_id", title, num, percent
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        num = try container.decode(Int.self, forKey: .num)
        percent = try container.decode(String.self, forKey: .percent)
    }
    static func == (lhs: PollOptionItem, rhs: PollOptionItem) -> Bool {
        return lhs.id == rhs.id &&
            lhs.title == rhs.title &&
            lhs.num == rhs.num &&
            lhs.percent == rhs.percent
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(num)
        hasher.combine(percent)
    }
}
typealias PollOptionItem = PollItem.Option
