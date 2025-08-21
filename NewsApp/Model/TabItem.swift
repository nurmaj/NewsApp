//
//  TabItem.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 18/1/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation
struct TabItem {
    var key, name: String
    var icon, sysIcName: IconItem?
    var canScrollLoad: Bool = false
    var queue: Int
    var iconUrl: URL?
    var layoutType: FeedLayout?
    var showViewNum: Bool = false
    var autoUpdate: Bool = false
    var launchable: Bool = false
    var lifetime: String?
}
extension TabItem: Codable {
    enum CodingKeys: String, CodingKey {
        case key, name="display_name", icon, sysIcName="system_icon", canScrollLoad="scroll_load", queue, iconUrl="icon_url", layoutType="layout_type", showViewNum="view_num", autoUpdate="update", launchable="for_main", lifetime
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key = try values.decode(String.self, forKey: .key)
        name = try values.decode(String.self, forKey: .name)
        icon = try values.decodeIfPresent(IconItem.self, forKey: .icon)
        sysIcName = try values.decodeIfPresent(IconItem.self, forKey: .sysIcName)
        canScrollLoad = try values.decodeIfPresent(Bool.self, forKey: .canScrollLoad) ?? false
        queue = try values.decode(Int.self, forKey: .queue)
        iconUrl = try values.decodeIfPresent(URL.self, forKey: .iconUrl)
        layoutType = try values.decodeIfPresent(FeedLayout.self, forKey: .layoutType)
        showViewNum = try values.decodeIfPresent(Bool.self, forKey: .showViewNum) ?? false
        autoUpdate = try values.decodeIfPresent(Bool.self, forKey: .autoUpdate) ?? false
        launchable = try values.decodeIfPresent(Bool.self, forKey: .launchable) ?? false
        lifetime = try values.decodeIfPresent(String.self, forKey: .lifetime)
    }
}
extension TabItem: Identifiable {
    var id: String { return key }
}
struct IconItem {
    let name: String
    let filled: String?
}
extension IconItem: Codable {
    enum CodingKeys: String, CodingKey {
        case name, filled
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        filled = try values.decodeIfPresent(String.self, forKey: .filled)
    }
}

struct ScrollTarget {
    var targetForScroll: String?
    var activeTabTargetPos: String = "N/A"
}
